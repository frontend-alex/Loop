import ComposableArchitecture
import Foundation
import Testing
@testable import loop

/// Uploading the draft to `PATCH /onboarding/{update|complete}` through a stubbed URL session.
@MainActor
struct OnboardingSyncTests {
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "loop.onboarding.sync-tests.\(UUID())"))
    }

    private func makeStore(
        _ state: OnboardingFeature.State,
        server: (session: URLSession, baseURL: URL),
        dependencies: (inout DependencyValues) -> Void = { _ in }
    ) -> TestStoreOf<OnboardingFeature> {
        TestStore(initialState: state) {
            OnboardingFeature()
        } withDependencies: {
            $0.defaultAppStorage = defaults
            $0.continuousClock = TestClock() // Auto-advance never fires on its own here.
            $0[APIClient.self] = .live(session: server.session, baseURL: server.baseURL)
            $0[AuthTokenStore.self].load = { "test-token" }
            dependencies(&$0)
        }
    }

    @Test func reconnectUploadsTheLatestDraftWithTheKeychainToken() async throws {
        let requests = LockIsolated<[URLRequest]>([])
        let server = try OnboardingURLProtocol.fixture(onRequest: { request in requests.withValue { $0.append(request) } })
        let store = makeStore(OnboardingFeature.State(isConnected: false), server: server) {
            $0[AuthTokenStore.self].load = { "keychain-test-token" }
        }

        await store.send(.singleAnswerSelected("get-up-on-time")) { $0.answers["morning-goal"] = .single("get-up-on-time") }
        await store.send(.singleAnswerSelected("build-routine")) { $0.answers["morning-goal"] = .single("build-routine") }
        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.pendingSync = .update
        }
        await store.send(.timeAnswerSelected(Date(timeIntervalSince1970: 0))) { $0.answers["workday-wake-time"] = .time(Date(timeIntervalSince1970: 0)) }
        #expect(requests.value.isEmpty)

        await store.send(.connectivityChanged(true)) { $0.isConnected = true }
        await store.receive(.syncSucceeded(.update)) { $0.pendingSync = nil }

        let request = try #require(requests.value.first)
        #expect(requests.value.count == 1)
        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path == "/api/v1/onboarding/update")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer keychain-test-token")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try JSONDecoder().decode(OnboardingRequest.self, from: try #require(request.httpBody))
        #expect(body == OnboardingRequest(
            answers: ["morning-goal": .single("build-routine"), "workday-wake-time": .time(Date(timeIntervalSince1970: 0))],
            currentStep: 1
        ))
        #expect(defaults.string(forKey: OnboardingFeature.pendingSyncKey) == nil)
    }

    @Test func serverFailureRetriesAutomaticallyWithoutBlockingNavigation() async throws {
        let clock = TestClock()
        let statuses = LockIsolated([500, 204])
        let server = try OnboardingURLProtocol.fixture(statusForRequest: { _ in statuses.withValue { $0.removeFirst() } })
        let store = makeStore(OnboardingFeature.State(), server: server) { $0.continuousClock = clock }

        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.pendingSync = .update
        }
        await store.receive(.syncFailed)
        #expect(OnboardingFeature.State.restored(from: defaults).pendingSync == .update)

        await clock.advance(by: .seconds(30))
        await store.receive(.syncPending)
        await store.receive(.syncSucceeded(.update)) { $0.pendingSync = nil }
    }

    @Test func answersAndClockChangesWithinAStepAreNotUploaded() async throws {
        let requests = LockIsolated(0)
        let server = try OnboardingURLProtocol.fixture(onRequest: { _ in requests.withValue { $0 += 1 } })
        let store = makeStore(OnboardingFeature.State(questionIndex: 1), server: server)

        await store.send(.timeAnswerSelected(Date(timeIntervalSince1970: 0))) {
            $0.answers["workday-wake-time"] = .time(Date(timeIntervalSince1970: 0))
        }
        await store.send(.timeAnswerSelected(Date(timeIntervalSince1970: 60))) {
            $0.answers["workday-wake-time"] = .time(Date(timeIntervalSince1970: 60))
        }
        await store.send(.backTapped) {
            $0.questionIndex = 0
            $0.isNavigatingBack = true
        }
        #expect(requests.value == 0)
        #expect(defaults.data(forKey: OnboardingFeature.draftKey) != nil)
    }

    @Test func aNewerStepReplacesAnUploadInFlight() async throws {
        let clock = TestClock()
        let requests = LockIsolated<[URLRequest]>([])
        let server = try OnboardingURLProtocol.fixture(onRequest: { request in requests.withValue { $0.append(request) } })
        let store = makeStore(OnboardingFeature.State(), server: server) {
            $0[AuthTokenStore.self].load = {
                try await clock.sleep(for: .seconds(1))
                return "test-token"
            }
        }

        await store.send(.singleAnswerSelected("build-routine")) { $0.answers["morning-goal"] = .single("build-routine") }
        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.pendingSync = .update
        }
        await store.send(.timeAnswerSelected(Date(timeIntervalSince1970: 0))) { $0.answers["workday-wake-time"] = .time(Date(timeIntervalSince1970: 0)) }
        await store.send(.nextTapped) { $0.questionIndex = 2 }

        await clock.advance(by: .seconds(1))
        await store.receive(.syncSucceeded(.update)) { $0.pendingSync = nil }

        #expect(requests.value.count == 1)
        let body = try JSONDecoder().decode(OnboardingRequest.self, from: try #require(requests.value.last?.httpBody))
        #expect(body == OnboardingRequest(
            answers: ["morning-goal": .single("build-routine"), "workday-wake-time": .time(Date(timeIntervalSince1970: 0))],
            currentStep: 2
        ))
    }

    @Test(arguments: [nil, ""] as [String?])
    func missingTokenKeepsTheDraftWithoutLoggingOut(token: String?) async throws {
        let requests = LockIsolated(0)
        let server = try OnboardingURLProtocol.fixture(onRequest: { _ in requests.withValue { $0 += 1 } })
        let store = makeStore(OnboardingFeature.State(), server: server) {
            $0[AuthTokenStore.self].load = { token }
        }

        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.pendingSync = .update
        }
        await store.receive(.authenticationRequired)
        #expect(requests.value == 0)
        #expect(defaults.data(forKey: OnboardingFeature.draftKey) != nil)
    }

    @Test func unauthorizedResponseRetainsTheDraftWithoutARetryLoop() async throws {
        let store = makeStore(OnboardingFeature.State(), server: try OnboardingURLProtocol.fixture(status: 401))

        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.pendingSync = .update
        }
        await store.receive(.authenticationRequired)
        #expect(store.state.pendingSync == .update)
        #expect(defaults.data(forKey: OnboardingFeature.draftKey) != nil)
    }

    @Test func offlineCompletionSurvivesRelaunchAndSyncsInTheBackground() async throws {
        let requests = LockIsolated<[URLRequest]>([])
        let server = try OnboardingURLProtocol.fixture(onRequest: { request in requests.withValue { $0.append(request) } })
        let store = makeStore(OnboardingFeature.State(step: .summary, isConnected: false), server: server)

        await store.send(.finishTapped) {
            $0.isCompleted = true
            $0.pendingSync = .complete
        }
        await store.receive(.delegate(.completed))
        #expect(defaults.data(forKey: OnboardingFeature.draftKey) != nil)

        let restored = OnboardingFeature.State.restored(from: defaults, isCompleted: false)
        #expect(restored.isCompleted)
        #expect(restored.pendingSync == .complete)

        let reopened = makeStore(restored, server: server)
        await reopened.send(.task)
        await reopened.receive(.syncSucceeded(.complete)) { $0.pendingSync = nil }

        #expect(requests.value.first?.url?.path == "/api/v1/onboarding/complete")
        #expect(defaults.data(forKey: OnboardingFeature.draftKey) == nil)
        #expect(defaults.string(forKey: OnboardingFeature.pendingSyncKey) == nil)
        #expect(defaults.bool(forKey: OnboardingFeature.completedKey))
    }

    @Test func networkMonitorAutomaticallyFlushesPendingDrafts() async throws {
        let connection = AsyncStream<Bool>.makeStream()
        let store = makeStore(OnboardingFeature.State(isConnected: false), server: try OnboardingURLProtocol.fixture()) {
            $0[NetworkMonitor.self].updates = { connection.stream }
        }

        await store.send(.task)
        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.pendingSync = .update
        }
        connection.continuation.yield(true)
        await store.receive(.connectivityChanged(true)) { $0.isConnected = true }
        await store.receive(.syncSucceeded(.update)) { $0.pendingSync = nil }
        connection.continuation.finish()
        await store.finish()
    }
}

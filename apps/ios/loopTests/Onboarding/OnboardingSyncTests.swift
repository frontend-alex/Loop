import ComposableArchitecture
import Foundation
import Testing
@testable import loop

@MainActor
struct OnboardingSyncTests {
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "loop.onboarding.sync-tests.\(UUID())"))
    }

    @Test func advancingSendsTheFullSnapshotAndKeychainToken() async throws {
        let requests = LockIsolated<[URLRequest]>([])
        let fixture = try OnboardingURLProtocol.fixture(onRequest: { request in
            requests.withValue { $0.append(request) }
        })
        let store = TestStore(initialState: OnboardingProvider.State()) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "keychain-test-token" }
        }

        await store.send(.singleAnswerSelected("High")) {
            $0.answers["focus"] = .single("High")
        }
        #expect(requests.value.isEmpty)
        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }

        let request = try #require(requests.value.first)
        #expect(requests.value.count == 1)
        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path == "/api/v1/onboarding/update")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer keychain-test-token")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let data = try #require(request.httpBody)
        let body = try JSONDecoder().decode(OnboardingRequest.self, from: data)
        #expect(body == OnboardingRequest(answers: ["focus": .single("High")], currentStep: 1))
        #expect(String(decoding: data, as: UTF8.self).contains("keychain-test-token") == false)
    }

    @Test func failedSavePreservesProgressAndCanBeRetried() async throws {
        let statuses = LockIsolated([500, 204])
        let fixture = try OnboardingURLProtocol.fixture(statusForRequest: { _ in
            statuses.withValue { $0.removeFirst() }
        })
        let store = TestStore(initialState: OnboardingProvider.State()) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "test-token" }
        }

        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncFailed("Could not save onboarding (HTTP 500). Please retry.")) {
            $0.isSyncing = false
            $0.syncErrorMessage = "Could not save onboarding (HTTP 500). Please retry."
        }
        #expect(OnboardingProvider.State.restored(from: defaults).questionIndex == 1)
        #expect(OnboardingProvider.State.restored(from: defaults).pendingSync == .update)
        await store.send(.nextTapped)
        await store.send(.backTapped)
        await store.send(.retrySyncTapped) {
            $0.isSyncing = true
            $0.syncErrorMessage = nil
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }
        #expect(defaults.string(forKey: OnboardingProvider.pendingSyncKey) == nil)
    }

    @Test(arguments: [nil, ""] as [String?])
    func missingTokenRequiresSignInWithoutSendingARequest(token: String?) async throws {
        let requests = LockIsolated(0)
        let fixture = try OnboardingURLProtocol.fixture(onRequest: { _ in requests.withValue { $0 += 1 } })
        let store = TestStore(initialState: OnboardingProvider.State()) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { token }
        }

        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.authenticationRequired) {
            $0.isSyncing = false
            $0.syncErrorMessage = "Please sign in again to save your progress."
        }
        await store.receive(.delegate(.authenticationRequired))
        #expect(requests.value == 0)
        #expect(defaults.data(forKey: OnboardingProvider.draftKey) != nil)
    }

    @Test func unauthorizedResponsePreservesTheDraftAndRequestsSignIn() async throws {
        let fixture = try OnboardingURLProtocol.fixture(status: 401)
        let store = TestStore(initialState: OnboardingProvider.State()) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "expired-test-token" }
        }

        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.authenticationRequired) {
            $0.isSyncing = false
            $0.syncErrorMessage = "Please sign in again to save your progress."
        }
        await store.receive(.delegate(.authenticationRequired))
        #expect(defaults.data(forKey: OnboardingProvider.draftKey) != nil)
        #expect(defaults.bool(forKey: OnboardingProvider.completedKey) == false)
    }

    @Test func failedCompletionResumesTheCompleteEndpointAfterRelaunch() async throws {
        let initial = OnboardingProvider.State(step: .summary)
        defaults.set(try JSONEncoder().encode(initial.draft), forKey: OnboardingProvider.draftKey)
        let failed = try OnboardingURLProtocol.fixture(status: 500)
        let store = TestStore(initialState: initial) {
            OnboardingProvider(defaults: defaults, session: failed.session, apiBaseURL: failed.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "test-token" }
        }

        await store.send(.finishTapped) {
            $0.isSyncing = true
            $0.pendingSync = .complete
        }
        await store.receive(.syncFailed("Could not save onboarding (HTTP 500). Please retry.")) {
            $0.isSyncing = false
            $0.syncErrorMessage = "Could not save onboarding (HTTP 500). Please retry."
        }
        #expect(defaults.data(forKey: OnboardingProvider.draftKey) != nil)
        #expect(defaults.bool(forKey: OnboardingProvider.completedKey) == false)

        let restored = OnboardingProvider.State.restored(from: defaults)
        #expect(restored.pendingSync == .complete)
        let requests = LockIsolated<[URLRequest]>([])
        let successful = try OnboardingURLProtocol.fixture(onRequest: { request in
            requests.withValue { $0.append(request) }
        })
        let reopened = TestStore(initialState: restored) {
            OnboardingProvider(defaults: defaults, session: successful.session, apiBaseURL: successful.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "test-token" }
        }

        await reopened.send(.task) {
            $0.isSyncing = true
        }
        await reopened.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
            $0.isCompleted = true
        }
        await reopened.receive(.delegate(.completed))
        #expect(requests.value.first?.url?.path == "/api/v1/onboarding/complete")
        #expect(defaults.data(forKey: OnboardingProvider.draftKey) == nil)
        #expect(defaults.string(forKey: OnboardingProvider.pendingSyncKey) == nil)
        #expect(defaults.bool(forKey: OnboardingProvider.completedKey))
    }

    @Test func inFlightSyncBlocksAllNavigation() async throws {
        let fixture = try OnboardingURLProtocol.fixture()
        let store = TestStore(initialState: OnboardingProvider.State(
            step: .summary, isSyncing: true, pendingSync: .update
        )) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        }

        await store.send(.nextTapped)
        await store.send(.backTapped)
        await store.send(.finishTapped)
        await store.send(.retrySyncTapped)
        #expect(store.state.step == .summary)
        #expect(store.state.isCompleted == false)
    }
}

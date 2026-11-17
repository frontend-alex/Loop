import ComposableArchitecture
import Foundation
import Testing
@testable import loop

@MainActor
struct AppFeatureTests {
    private let defaults: UserDefaults
    private let user = User(
        id: 42, email: "user@example.com", name: "Alex", avatarURL: "",
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0)
    )

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "loop.app.tests.\(UUID())"))
    }

    private func makeStore(
        _ state: AppFeature.State? = nil,
        dependencies: (inout DependencyValues) -> Void = { _ in }
    ) -> TestStoreOf<AppFeature> {
        TestStore(initialState: state ?? authenticatedState()) {
            AppFeature()
        } withDependencies: {
            $0.defaultAppStorage = defaults
            dependencies(&$0)
        }
    }

    @Test(arguments: [true, false])
    func serverResponseDeterminesTheRoute(requiresOnboarding: Bool) async {
        defaults.set(requiresOnboarding, forKey: "user.42.onboarding.completed")
        let response = UserResponse(user: user, requiresOnboarding: requiresOnboarding)
        let store = makeStore {
            $0[APIClient.self].fetchUser = { response }
        }

        await store.send(.auth(.delegate(.authenticated))) {
            $0.route = .loadingUser
        }
        // Assert routing/account fields without asserting the fresh alarm's wall-clock timestamp.
        await store.withExhaustivity(.off) {
            await store.receive(.userFetched(response)) {
                $0.user = user
                $0.onboarding.userID = user.id
                $0.onboarding.isCompleted = !requiresOnboarding
                $0.route = requiresOnboarding ? .onboarding : .home
            }
        }
        await store.receive(.onboarding(.task))
    }

    @Test func restoredTokenFetchesTheUserBeforeShowingHome() async {
        let response = UserResponse(user: user, requiresOnboarding: false)
        let store = makeStore(AppFeature.State()) {
            $0[AuthTokenStore.self].load = { "session-token" }
            $0[APIClient.self].fetchUser = { response }
        }

        await store.send(.splashFinished)
        await store.receive(.auth(.task)) { $0.auth.isLoading = true }
        await store.receive(\.auth.sessionResolved) {
            $0.auth.session = AuthSession(token: "session-token")
            $0.auth.isLoading = false
        }
        await store.receive(.auth(.delegate(.authenticated))) { $0.route = .loadingUser }
        await store.withExhaustivity(.off) {
            await store.receive(.userFetched(response)) {
                $0.user = user
                $0.onboarding.userID = user.id
                $0.onboarding.isCompleted = true
                $0.route = .home
            }
        }
        await store.receive(.onboarding(.task))
    }

    @Test func failedFetchStaysOnRetryScreenAndCanRecover() async {
        let response = UserResponse(user: user, requiresOnboarding: false)
        let attempts = LockIsolated(0)
        let store = makeStore {
            $0[APIClient.self].fetchUser = {
                let attempt = attempts.withValue {
                    $0 += 1
                    return $0
                }
                if attempt == 1 { throw URLError(.notConnectedToInternet) }
                return response
            }
        }

        await store.send(.auth(.delegate(.authenticated))) { $0.route = .loadingUser }
        await store.receive(.userFetchFailed) {
            $0.userError = "Could not load your account. Please retry."
        }
        await store.send(.retryUserFetch) { $0.userError = nil }
        await store.withExhaustivity(.off) {
            await store.receive(.userFetched(response)) {
                $0.user = user
                $0.onboarding.userID = user.id
                $0.onboarding.isCompleted = true
                $0.route = .home
            }
        }
        await store.receive(.onboarding(.task))
    }

    @Test func signingInFetchesTheUserAfterSavingTheToken() async {
        let response = UserResponse(user: user, requiresOnboarding: false)
        let savedToken = LockIsolated<String?>(nil)
        let store = makeStore(AppFeature.State(route: .auth)) {
            $0[AuthClient.self].authenticate = { _ in AuthSession(token: "session-token") }
            $0[AuthTokenStore.self].save = { savedToken.setValue($0) }
            $0[APIClient.self].fetchUser = {
                #expect(savedToken.value == "session-token")
                return response
            }
        }

        await store.send(.auth(.loginTapped(.google))) { $0.auth.isLoading = true }
        await store.receive(.auth(.sessionResolved(AuthSession(token: "session-token")))) {
            $0.auth.session = AuthSession(token: "session-token")
            $0.auth.isLoading = false
        }
        await store.receive(.auth(.delegate(.authenticated))) { $0.route = .loadingUser }
        await store.withExhaustivity(.off) {
            await store.receive(.userFetched(response)) {
                $0.user = user
                $0.onboarding.userID = user.id
                $0.onboarding.isCompleted = true
                $0.route = .home
            }
        }
        await store.receive(.onboarding(.task))
    }

    @Test func loggingOutCancelsAnInFlightUserFetch() async {
        let clock = TestClock()
        let response = UserResponse(user: user, requiresOnboarding: false)
        let store = makeStore {
            $0[APIClient.self].fetchUser = {
                try await clock.sleep(for: .seconds(1))
                return response
            }
            $0[AuthTokenStore.self].delete = {}
        }
        store.exhaustivity = .off

        await store.send(.auth(.delegate(.authenticated)))
        await store.send(.auth(.logout))
        await store.receive(.auth(.delegate(.unauthenticated)))
        await clock.advance(by: .seconds(1))
        await store.finish()

        #expect(store.state.route == .auth)
        #expect(store.state.user == nil)
    }

    @Test func unauthorizedResponseClearsTheTokenAndShowsAuthentication() async {
        let deleted = LockIsolated(false)
        let store = makeStore {
            $0[APIClient.self].fetchUser = { throw APIClient.Failure.unauthorized }
            $0[AuthTokenStore.self].delete = { deleted.setValue(true) }
        }
        // A reset creates a fresh default alarm timestamp; assert session/routing explicitly.
        store.exhaustivity = .off

        await store.send(.auth(.delegate(.authenticated)))
        await store.receive(.userUnauthorized)
        await store.receive(.auth(.logout))
        await store.receive(.auth(.delegate(.unauthenticated)))
        #expect(store.state.route == .auth)
        #expect(store.state.auth.session == nil)
        #expect(store.state.user == nil)
        #expect(store.state.onboarding.userID == nil)
        #expect(deleted.value)
    }

    @Test(arguments: [false, true])
    func clearingTokenAfterAccountLoadFailure(deleteFails: Bool) async {
        let deleted = LockIsolated(false)
        let store = makeStore {
            $0[APIClient.self].fetchUser = { throw URLError(.notConnectedToInternet) }
            $0[AuthTokenStore.self].delete = {
                if deleteFails { throw KeychainError.invalidData }
                deleted.setValue(true)
            }
        }

        await store.send(.auth(.delegate(.authenticated))) { $0.route = .loadingUser }
        await store.receive(.userFetchFailed) {
            $0.userError = "Could not load your account. Please retry."
        }
        await store.send(.auth(.logout)) { $0.auth.isLoading = true }

        if deleteFails {
            await store.receive(.auth(.logoutFailed)) {
                $0.auth.isLoading = false
                $0.auth.errorMessage = "Could not sign out. Please try again."
            }
            #expect(store.state.route == .loadingUser)
            #expect(store.state.auth.session?.token == "session-token")
            #expect(!deleted.value)
        } else {
            await store.receive(.auth(.logoutSucceeded)) {
                $0.auth.session = nil
                $0.auth.isLoading = false
            }
            await store.withExhaustivity(.off) {
                await store.receive(.auth(.delegate(.unauthenticated))) {
                    $0.route = .auth
                    $0.userError = nil
                }
            }
            #expect(store.state.user == nil)
            #expect(deleted.value)
        }
    }

    @Test func failedLogoutPreservesTheSessionAndRoute() async {
        var state = authenticatedState()
        state.route = .home
        state.user = user
        let store = makeStore(state) {
            $0[AuthTokenStore.self].delete = { throw KeychainError.invalidData }
        }

        await store.send(.auth(.logout)) { $0.auth.isLoading = true }
        await store.receive(.auth(.logoutFailed)) {
            $0.auth.isLoading = false
            $0.auth.errorMessage = "Could not sign out. Please try again."
        }
        #expect(store.state.route == .home)
        #expect(store.state.user == user)
    }

    @Test func draftsAreRestoredOnlyForTheirUser() throws {
        let draft = OnboardingDraft(questionIndex: 2, answers: ["morning-goal": .single("build-routine")])
        defaults.set(try JSONEncoder().encode(draft), forKey: "user.42.onboarding.draft")
        defaults.set(true, forKey: "user.42.onboarding.completed")

        let restored = OnboardingFeature.State.restored(from: defaults, userID: 42, isCompleted: false)
        let other = OnboardingFeature.State.restored(from: defaults, userID: 43, isCompleted: false)

        #expect(restored.questionIndex == 2)
        #expect(restored.answers == draft.answers)
        #expect(restored.isCompleted == false)
        #expect(other.questionIndex == 0)
        #expect(other.answers.isEmpty)
    }

    @Test func locallyCompletedOnboardingStaysOnHomeWhileCompletionIsPending() async throws {
        let draft = OnboardingDraft(step: .summary, answers: ["morning-goal": .single("build-routine")])
        defaults.set(try JSONEncoder().encode(draft), forKey: "user.42.onboarding.draft")
        defaults.set(true, forKey: "user.42.onboarding.completed")
        defaults.set("complete", forKey: "user.42.onboarding.pending-sync")
        let response = UserResponse(user: user, requiresOnboarding: true)
        let store = makeStore {
            $0[APIClient.self].fetchUser = { response }
            $0[APIClient.self].updateOnboarding = { _, _ in throw APIClient.Failure.unauthorized }
        }
        store.exhaustivity = .off

        await store.send(.auth(.delegate(.authenticated)))
        await store.receive(.userFetched(response))
        #expect(store.state.route == .home)
        #expect(store.state.onboarding.isCompleted)
        #expect(store.state.onboarding.answers == draft.answers)
        await store.receive(.onboarding(.task))
        await store.receive(.onboarding(.authenticationRequired))
        #expect(store.state.onboarding.pendingSync == .complete)
        #expect(store.state.route == .home)
        #expect(defaults.data(forKey: "user.42.onboarding.draft") != nil)
    }

    @Test func loggingOutStopsMonitoringConnectivity() async {
        let connection = AsyncStream<Bool>.makeStream()
        let terminated = LockIsolated(false)
        connection.continuation.onTermination = { _ in terminated.setValue(true) }
        let store = makeStore {
            $0[NetworkMonitor.self].updates = { connection.stream }
            $0[AuthTokenStore.self].delete = {}
        }
        store.exhaustivity = .off

        await store.send(.onboarding(.task))
        await store.send(.auth(.logout))
        await store.receive(.auth(.delegate(.unauthenticated)))
        await store.finish()
        #expect(terminated.value)
        #expect(store.state.route == .auth)
    }

    private func authenticatedState() -> AppFeature.State {
        var state = AppFeature.State(route: .auth)
        state.auth.session = AuthSession(token: "session-token")
        return state
    }
}

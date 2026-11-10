import ComposableArchitecture
import Foundation
import Testing
@testable import loop

@MainActor
struct AppProviderTests {
    private let defaults: UserDefaults
    private let user = User(
        id: 42, email: "user@example.com", name: "Alex", avatarURL: "",
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0)
    )

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "loop.user-routing.tests.\(UUID())"))
    }

    @Test(arguments: [true, false])
    func serverResponseDeterminesTheRoute(requiresOnboarding: Bool) async {
        defaults.set(requiresOnboarding, forKey: "user.42.onboarding.completed")
        let response = UserResponse(user: user, requiresOnboarding: requiresOnboarding)
        let store = TestStore(initialState: authenticatedState()) {
            AppProvider(defaults: defaults)
        } withDependencies: {
            $0[UserClient.self].fetch = { token in
                #expect(token == "session-token")
                return response
            }
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
        if requiresOnboarding {
            await store.receive(.onboarding(.task))
        }
    }

    @Test func restoredTokenFetchesTheUserBeforeShowingHome() async {
        let response = UserResponse(user: user, requiresOnboarding: false)
        let store = TestStore(initialState: AppProvider.State()) {
            AppProvider(defaults: defaults)
        } withDependencies: {
            $0.authTokenStore.load = { "session-token" }
            $0[UserClient.self].fetch = { _ in response }
        }

        await store.send(.splashFinished)
        await store.receive(.auth(.task)) { $0.auth.isLoading = true }
        await store.receive(\.auth.sessionRestored) {
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
    }

    @Test func failedFetchStaysOnRetryScreenAndCanRecover() async {
        let response = UserResponse(user: user, requiresOnboarding: false)
        let attempts = LockIsolated(0)
        let store = TestStore(initialState: authenticatedState()) {
            AppProvider(defaults: defaults)
        } withDependencies: {
            $0[UserClient.self].fetch = { _ in
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
        #expect(store.state.route == .loadingUser)
        await store.send(.retryUserFetch) { $0.userError = nil }
        await store.withExhaustivity(.off) {
            await store.receive(.userFetched(response)) {
                $0.user = user
                $0.onboarding.userID = user.id
                $0.onboarding.isCompleted = true
                $0.route = .home
            }
        }
    }

    @Test func signingInFetchesTheUserAfterSavingTheToken() async {
        let response = UserResponse(user: user, requiresOnboarding: false)
        let savedToken = LockIsolated<String?>(nil)
        let store = TestStore(initialState: AppProvider.State(route: .auth)) {
            AppProvider(defaults: defaults)
        } withDependencies: {
            $0[AuthClient.self].authenticate = { _ in AuthSession(token: "session-token") }
            $0.authTokenStore.save = { savedToken.setValue($0) }
            $0[UserClient.self].fetch = { token in
                #expect(savedToken.value == token)
                return response
            }
        }

        await store.send(.auth(.loginTapped(.google))) { $0.auth.isLoading = true }
        await store.receive(.auth(.sessionRestored(AuthSession(token: "session-token")))) {
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
    }

    @Test func loggingOutCancelsAnInFlightUserFetch() async {
        let clock = TestClock()
        let response = UserResponse(user: user, requiresOnboarding: false)
        let store = TestStore(initialState: authenticatedState()) {
            AppProvider(defaults: defaults)
        } withDependencies: {
            $0[UserClient.self].fetch = { _ in
                try await clock.sleep(for: .seconds(1))
                return response
            }
            $0.authTokenStore.delete = {}
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
        let store = TestStore(initialState: authenticatedState()) {
            AppProvider(defaults: defaults)
        } withDependencies: {
            $0[UserClient.self].fetch = { _ in throw UserClient.Failure.unauthorized }
            $0.authTokenStore.delete = { deleted.setValue(true) }
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

    @Test func draftsAreRestoredOnlyForTheirUser() throws {
        let draft = OnboardingDraft(questionIndex: 2, answers: ["focus": .single("High")])
        let data = try JSONEncoder().encode(draft)
        defaults.set(data, forKey: "user.42.onboarding.draft")
        defaults.set(true, forKey: "user.42.onboarding.completed")

        let restored = OnboardingProvider.State.restored(
            from: defaults, userID: 42, isCompleted: false
        )
        let other = OnboardingProvider.State.restored(
            from: defaults, userID: 43, isCompleted: false
        )

        #expect(restored.questionIndex == 2)
        #expect(restored.answers == draft.answers)
        #expect(restored.isCompleted == false)
        #expect(other.questionIndex == 0)
        #expect(other.answers.isEmpty)
    }

    private func authenticatedState() -> AppProvider.State {
        var state = AppProvider.State(route: .auth)
        state.auth.session = AuthSession(token: "session-token")
        return state
    }
}

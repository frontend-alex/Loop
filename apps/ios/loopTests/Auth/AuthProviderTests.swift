import ComposableArchitecture
import Testing
@testable import loop

@MainActor
struct AuthProviderTests {
    @Test(arguments: [String?.none, "saved-token"])
    func restorationResolvesBeforeRouting(token: String?) async {
        let store = TestStore(initialState: AuthProvider.State(errorMessage: "Old error")) {
            AuthProvider()
        } withDependencies: {
            $0[AuthTokenStore.self].load = { token }
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        let session = token.map { AuthSession(token: $0) }
        await store.receive(.sessionResolved(session)) {
            $0.session = session
            $0.isLoading = false
        }
        await store.receive(.delegate(session == nil ? .unauthenticated : .authenticated))
    }

    @Test func restorationFailureClearsLoadingBeforeRouting() async {
        let store = TestStore(initialState: AuthProvider.State()) {
            AuthProvider()
        } withDependencies: {
            $0[AuthTokenStore.self].load = { throw KeychainError.invalidData }
        }

        await store.send(.task) { $0.isLoading = true }
        await store.receive(.sessionRestoreFailed) {
            $0.isLoading = false
            $0.errorMessage = "Could not read your saved session."
        }
        await store.receive(.delegate(.unauthenticated))
    }

    @Test func cancelledSignInCanBeRetried() async {
        let attempts = LockIsolated(0)
        let savedToken = LockIsolated<String?>(nil)
        let session = AuthSession(token: "new-token")
        let store = TestStore(initialState: AuthProvider.State(errorMessage: "Old error")) {
            AuthProvider()
        } withDependencies: {
            $0[AuthClient.self].authenticate = { provider in
                #expect(provider == .google)
                let attempt = attempts.withValue {
                    $0 += 1
                    return $0
                }
                if attempt == 1 { throw AuthClientError.authenticationCancelled }
                return session
            }
            $0[AuthTokenStore.self].save = { savedToken.setValue($0) }
        }

        await store.send(.loginTapped(.google)) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(.authenticationCancelled) { $0.isLoading = false }
        await store.send(.loginTapped(.google)) { $0.isLoading = true }
        await store.receive(.sessionResolved(session)) {
            $0.session = session
            $0.isLoading = false
        }
        #expect(savedToken.value == session.token)
        await store.receive(.delegate(.authenticated))
    }

    @Test(arguments: [false, true])
    func signInAndPersistenceFailuresDoNotAuthenticate(saveFails: Bool) async {
        let store = TestStore(initialState: AuthProvider.State()) {
            AuthProvider()
        } withDependencies: {
            $0[AuthClient.self].authenticate = { _ in
                if !saveFails { throw AuthClientError.failedToStart }
                return AuthSession(token: "new-token")
            }
            $0[AuthTokenStore.self].save = { _ in throw KeychainError.invalidData }
        }

        await store.send(.loginTapped(.apple)) { $0.isLoading = true }
        await store.receive(.authenticationFailed) {
            $0.isLoading = false
            $0.errorMessage = "Could not sign in. Please try again."
        }
        #expect(store.state.session == nil)
    }

    @Test(arguments: [false, true])
    func logoutClearsTheSessionOnlyAfterSuccessfulDeletion(deleteFails: Bool) async {
        let session = AuthSession(token: "saved-token")
        let store = TestStore(initialState: AuthProvider.State(session: session)) {
            AuthProvider()
        } withDependencies: {
            $0[AuthTokenStore.self].delete = {
                if deleteFails { throw KeychainError.invalidData }
            }
        }

        await store.send(.logout) { $0.isLoading = true }
        #expect(store.state.session == session)
        if deleteFails {
            await store.receive(.logoutFailed) {
                $0.isLoading = false
                $0.errorMessage = "Could not sign out. Please try again."
            }
            #expect(store.state.session == session)
        } else {
            await store.receive(.logoutSucceeded) {
                $0.session = nil
                $0.isLoading = false
            }
            await store.receive(.delegate(.unauthenticated))
        }
    }

    @Test func busyStateIgnoresNewOperations() async {
        let store = TestStore(initialState: AuthProvider.State(isLoading: true)) {
            AuthProvider()
        }

        await store.send(.task)
        await store.send(.loginTapped(.google))
        await store.send(.logout)
    }

    @Test func existingSessionIgnoresRestorationAndLogin() async {
        let store = TestStore(
            initialState: AuthProvider.State(session: AuthSession(token: "saved-token"))
        ) {
            AuthProvider()
        }

        await store.send(.task)
        await store.send(.loginTapped(.apple))
    }

    @Test func logoutWithoutASessionDoesNothing() async {
        let store = TestStore(initialState: AuthProvider.State()) {
            AuthProvider()
        }

        await store.send(.logout)
    }
}

import ComposableArchitecture

struct AuthClient: Sendable {
    var authenticate:
        @Sendable (AuthProviderKind) async throws -> AuthSession
}

enum AuthClientError: Error, Equatable, Sendable {
    case invalidURL
    case invalidCallback
    case authenticationCancelled
}


extension AuthClient: DependencyKey {
    static let liveValue = Self(
        authenticate: { provider in
            #if DEBUG && !targetEnvironment(simulator)
            return await AuthSession(token: AppEnvironment.current.authToken)
            #else
            return try await WebAuthenticationSession(provider: provider).authenticate()
            #endif
        }
    )

    static let testValue = Self(
        authenticate: { _ in
            AuthSession(token: "test-token")
        }
    )
}
extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}


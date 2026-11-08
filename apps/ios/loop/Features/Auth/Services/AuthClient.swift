import ComposableArchitecture

struct AuthClient: Sendable {
    var authenticate:
        @Sendable (AuthProviderKind) async throws -> AuthSession
}

extension AuthClient: DependencyKey {
    static let liveValue = Self(
        authenticate: { provider in
            try await WebAuthenticationSession(
                provider: provider
            ).authenticate()
        }
    )

    static let testValue = Self(
        authenticate: { _ in
            AuthSession(token: "test-token")
        }
    )
}

enum AuthClientError: Error, Equatable, Sendable {
    case invalidURL
    case invalidCallback
    case authenticationCancelled
}

import ComposableArchitecture

struct AuthClient: Sendable, DependencyKey {
    var authenticate: @Sendable (AuthProviderKind) async throws -> AuthSession

    static let liveValue = Self(
        authenticate: { provider in
            #if DEBUG && !targetEnvironment(simulator)
            return await AuthSession(token: AppEnvironment.current.authToken)
            #else
            return try await WebAuthenticationSession(provider: provider)
                .authenticate()
            #endif
        }
    )
}

enum AuthClientError: Error, Equatable, Sendable {
    case invalidURL
    case invalidCallback
    case authenticationCancelled
    case failedToStart
}

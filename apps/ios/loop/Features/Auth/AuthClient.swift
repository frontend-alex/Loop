import AuthenticationServices
import ComposableArchitecture
import UIKit

nonisolated struct AuthSession: Equatable, Sendable {
    let token: String
}

nonisolated enum AuthProviderKind: String, Equatable, Sendable {
    case google
    case apple
}

nonisolated enum AuthClientError: Error, Equatable, Sendable {
    case invalidCallback
    case authenticationCancelled
    case failedToStart
}

struct AuthClient: Sendable, DependencyKey {
    var authenticate: @Sendable (AuthProviderKind) async throws -> AuthSession

    static let liveValue = Self(
        authenticate: { provider in
            #if DEBUG && !targetEnvironment(simulator)
            return AuthSession(token: AppEnvironment.current.authToken)
            #else
            return try await WebAuthentication(provider: provider).start()
            #endif
        }
    )
}

/// Runs the backend's OAuth flow and reads the token from `loop://auth/callback?token=…`.
@MainActor
private final class WebAuthentication: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let provider: AuthProviderKind
    private var continuation: CheckedContinuation<AuthSession, Error>?

    init(provider: AuthProviderKind) {
        self.provider = provider
    }

    func start() async throws -> AuthSession {
        let url = AppEnvironment.current.apiBaseURL.appending(components: "auth", provider.rawValue)
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "loop") { url, error in
                Task { @MainActor in self.finish(callbackURL: url, error: error) }
            }
            session.presentationContextProvider = self
            if !session.start() {
                resume(.failure(AuthClientError.failedToStart))
            }
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes[0]
        return scene.keyWindow ?? ASPresentationAnchor(windowScene: scene)
    }

    private func finish(callbackURL: URL?, error: Error?) {
        if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
            return resume(.failure(AuthClientError.authenticationCancelled))
        }
        if let error { return resume(.failure(error)) }

        guard let callbackURL,
              callbackURL.host == "auth",
              callbackURL.path == "/callback",
              let token = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "token" })?.value,
              !token.isEmpty
        else { return resume(.failure(AuthClientError.invalidCallback)) }

        resume(.success(AuthSession(token: token)))
    }

    private func resume(_ result: Result<AuthSession, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}

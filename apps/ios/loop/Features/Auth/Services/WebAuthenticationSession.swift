import AuthenticationServices
import UIKit

@MainActor
final class WebAuthenticationSession:
    NSObject,
    ASWebAuthenticationPresentationContextProviding
{
    private let provider: AuthProviderKind
    private var continuation: CheckedContinuation<AuthSession, Error>?

    init(provider: AuthProviderKind) {
        self.provider = provider
    }

    func authenticate() async throws -> AuthSession {
        let url = AppEnvironment.current.apiBaseURL
            .appendingPathComponent("auth")
            .appendingPathComponent(provider.rawValue)

        guard let scheme = url.scheme,
              ["http", "https"].contains(scheme),
              url.host != nil
        else {
            throw AuthClientError.invalidURL
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "loop"
            ) { callbackURL, error in
                Task { @MainActor in
                    self.complete(callbackURL: callbackURL, error: error)
                }
            }

            session.presentationContextProvider = self

            if !session.start() {
                finish(.failure(AuthClientError.failedToStart))
            }
        }
    }

    func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        return scene?.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    private func complete(callbackURL: URL?, error: Error?) {
        if let error {
            if let webError = error as? ASWebAuthenticationSessionError,
               webError.code == .canceledLogin {
                finish(.failure(AuthClientError.authenticationCancelled))
            } else {
                finish(.failure(error))
            }
            return
        }

        guard let callbackURL else {
            finish(.failure(AuthClientError.invalidCallback))
            return
        }

        finish(Result {
            try AuthCallbackParser.session(from: callbackURL)
        })
    }

    private func finish(_ result: Result<AuthSession, Error>) {
        guard let continuation else { return }

        self.continuation = nil
        continuation.resume(with: result)
    }
}

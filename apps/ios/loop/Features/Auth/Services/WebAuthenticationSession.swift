import AuthenticationServices
import UIKit

@MainActor
final class WebAuthenticationSession:
    NSObject,
    ASWebAuthenticationPresentationContextProviding
{
    private let provider: AuthProviderKind
    private var authenticationSession: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<AuthSession, Error>?

    init(provider: AuthProviderKind) {
        self.provider = provider
    }

    func authenticate() async throws -> AuthSession {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            do {
                let endpoint = try authenticationURL()

                let session = ASWebAuthenticationSession(
                    url: endpoint,
                    callbackURLScheme: "loop"
                ) { [weak self] callbackURL, error in
                    Task { @MainActor in
                        self?.handleCompletion(
                            callbackURL: callbackURL,
                            error: error
                        )
                    }
                }

                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = false
                authenticationSession = session

                guard session.start() else {
                    finish(with: .failure(AuthClientError.authenticationCancelled))
                    return
                }
            } catch {
                finish(with: .failure(error))
            }
        }
    }

    func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else {
            return ASPresentationAnchor()
        }

        return window
    }

    private func authenticationURL() throws -> URL {
        let endpoint = AppEnvironment.current.apiBaseURL
            .appendingPathComponent("auth")
            .appendingPathComponent(provider.backendPath)

        guard
            let scheme = endpoint.scheme,
            ["http", "https"].contains(scheme),
            endpoint.host != nil
        else {
            throw AuthClientError.invalidURL
        }

        return endpoint
    }

    private func handleCompletion(
        callbackURL: URL?,
        error: Error?
    ) {
        if let error {
            if let authenticationError = error as? ASWebAuthenticationSessionError,
               authenticationError.code == .canceledLogin {
                finish(with: .failure(AuthClientError.authenticationCancelled))
            } else {
                finish(with: .failure(error))
            }
            return
        }

        guard let callbackURL else {
            finish(with: .failure(AuthClientError.invalidCallback))
            return
        }

        do {
            finish(
                with: .success(
                    try AuthCallbackParser.session(from: callbackURL)
                )
            )
        } catch {
            finish(with: .failure(error))
        }
    }

    private func finish(
        with result: Result<AuthSession, Error>
    ) {
        authenticationSession = nil

        guard let continuation else {
            return
        }

        self.continuation = nil
        continuation.resume(with: result)
    }
}

//
//  AuthClient.swift
//  loop
//
//  Created by Aleksander Ivanov on 09/10/2026.
//

import AuthenticationServices
import ComposableArchitecture
import Foundation
import UIKit

struct AuthClient: Sendable {
    var authenticate:
        @Sendable (AuthProviderKind) async throws -> AuthSession
}

extension AuthClient: DependencyKey {
    static let liveValue = Self(
        authenticate: { provider in
            try await WebAuthentication(provider: provider).authenticate()
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

enum AuthClientError: Error, Equatable, Sendable {
    case invalidURL
    case invalidCallback
    case authenticationCancelled
}

@MainActor
private final class WebAuthentication:
    NSObject,
    ASWebAuthenticationPresentationContextProviding
{
    private let provider: AuthProviderKind
    private var authenticationSession: ASWebAuthenticationSession?
    private var continuation:
        CheckedContinuation<AuthSession, Error>?

    init(provider: AuthProviderKind) {
        self.provider = provider
    }

    func authenticate() async throws -> AuthSession {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let endpoint = AppEnvironment.current.apiBaseURL
//                .appendingPathComponent("api")
//                .appendingPathComponent("v1")
                .appendingPathComponent("auth")
                .appendingPathComponent(provider.backendPath)

            let url = endpoint
            print(endpoint)

            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "loop"
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    self?.handleCallback(
                        callbackURL: callbackURL,
                        error: error
                    )
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            authenticationSession = session

            guard session.start() else {
                finish(
                    with: .failure(
                        AuthClientError.authenticationCancelled
                    )
                )
                return
            }
        }
    }

    func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
            let window = windowScene.windows.first
        else {
            return ASPresentationAnchor()
        }

        return window
    }

    private func handleCallback(
        callbackURL: URL?,
        error: Error?
    ) {
        if let error {
            finish(with: .failure(error))
            return
        }

        guard
            let callbackURL,
            let token = URLComponents(
                url: callbackURL,
                resolvingAgainstBaseURL: false
            )?
            .queryItems?
            .first(where: { $0.name == "token" })?
            .value,
            !token.isEmpty
        else {
            finish(with: .failure(AuthClientError.invalidCallback))
            return
        }

        finish(
            with: .success(
                AuthSession(token: token)
            )
        )
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

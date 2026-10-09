import ComposableArchitecture
import Foundation

struct AuthKeychainClient: Sendable {
    var saveToken: @Sendable (String) async throws -> Void
    var readToken: @Sendable () async throws -> String?
    var deleteToken: @Sendable () async throws -> Void
}

extension AuthKeychainClient: DependencyKey {
    static let liveValue = Self(
        saveToken: { token in
            guard let data = token.data(using: .utf8) else {
                throw AuthKeychainError.invalidToken
            }

            try await KeychainStore.shared.save(
                data: data,
                service: AuthKeychainKeys.service,
                account: AuthKeychainKeys.accessToken
            )
        },
        readToken: {
            guard
                let data = try await KeychainStore.shared.read(
                    service: AuthKeychainKeys.service,
                    account: AuthKeychainKeys.accessToken
                )
            else {
                return nil
            }

            guard let token = String(data: data, encoding: .utf8) else {
                throw AuthKeychainError.invalidStoredToken
            }

            return token
        },
        deleteToken: {
            try await KeychainStore.shared.delete(
                service: AuthKeychainKeys.service,
                account: AuthKeychainKeys.accessToken
            )
        }
    )

    static let testValue = Self(
        saveToken: { _ in },
        readToken: { nil },
        deleteToken: {}
    )
}

extension DependencyValues {
    var authKeychainClient: AuthKeychainClient {
        get { self[AuthKeychainClient.self] }
        set { self[AuthKeychainClient.self] = newValue }
    }
}

private enum AuthKeychainKeys {
    static let service = "com.loop.auth"
    static let accessToken = "access-token"
}

enum AuthKeychainError: Error, Equatable, Sendable {
    case invalidToken
    case invalidStoredToken
}

import ComposableArchitecture
import Foundation

struct AuthTokenStore: Sendable {
    var save: @Sendable (String) async throws -> Void
    var load: @Sendable () async throws -> String?
    var delete: @Sendable () async throws -> Void
}

extension AuthTokenStore: DependencyKey {
    static let liveValue = Self(
        save: { token in
            guard let data = token.data(using: .utf8) else {
                throw KeychainError.invalidData
            }

            try await KeychainStore.shared.save(
                data: data,
                service: AuthTokenStoreKeys.service,
                account: AuthTokenStoreKeys.accessToken
            )
        },
        load: {
            guard let data = try await KeychainStore.shared.read(
                service: AuthTokenStoreKeys.service,
                account: AuthTokenStoreKeys.accessToken
            ) else {
                return nil
            }

            guard let token = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }

            return token
        },
        delete: {
            try await KeychainStore.shared.delete(
                service: AuthTokenStoreKeys.service,
                account: AuthTokenStoreKeys.accessToken
            )
        }
    )

    static let testValue = Self(
        save: { _ in },
        load: { nil },
        delete: {}
    )
}

extension DependencyValues {
    var authTokenStore: AuthTokenStore {
        get { self[AuthTokenStore.self] }
        set { self[AuthTokenStore.self] = newValue }
    }
}

private enum AuthTokenStoreKeys {
    static let service = "com.loop.auth"
    static let accessToken = "access-token"
}

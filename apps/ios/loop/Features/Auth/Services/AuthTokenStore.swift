import ComposableArchitecture
import Foundation

struct AuthTokenStore: Sendable, DependencyKey {
    var save: @Sendable (String) async throws -> Void
    var load: @Sendable () async throws -> String?
    var delete: @Sendable () async throws -> Void

    static let liveValue = Self(
        save: { token in
            try await KeychainStore.shared.save(
                data: Data(token.utf8),
                service: Keys.service,
                account: Keys.accessToken
            )
        },
        load: {
            guard let data = try await KeychainStore.shared.read(
                service: Keys.service,
                account: Keys.accessToken
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
                service: Keys.service,
                account: Keys.accessToken
            )
        }
    )

    private enum Keys {
        static let service = "com.loop.auth"
        static let accessToken = "access-token"
    }
}

import ComposableArchitecture
import Foundation
import Security

nonisolated enum KeychainError: Error, Equatable, Sendable {
    case osStatus(OSStatus)
    case invalidData
}

/// The access token, stored in the keychain.
struct AuthTokenStore: Sendable, DependencyKey {
    var save: @Sendable (String) async throws -> Void
    var load: @Sendable () async throws -> String?
    var delete: @Sendable () async throws -> Void

    static let liveValue = Self(
        save: { token in
            let data = Data(token.utf8)
            var status = SecItemAdd(query([
                kSecValueData: data,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]), nil)
            if status == errSecDuplicateItem {
                status = SecItemUpdate(query(), [kSecValueData: data] as CFDictionary)
            }
            guard status == errSecSuccess else { throw KeychainError.osStatus(status) }
        },
        load: {
            var result: AnyObject?
            let status = SecItemCopyMatching(query([kSecReturnData: true, kSecMatchLimit: kSecMatchLimitOne]), &result)
            if status == errSecItemNotFound { return nil }
            guard status == errSecSuccess else { throw KeychainError.osStatus(status) }
            guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return token
        },
        delete: {
            let status = SecItemDelete(query())
            guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.osStatus(status) }
        }
    )
}

private nonisolated func query(_ attributes: [CFString: Any] = [:]) -> CFDictionary {
    let base: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: "com.loop.auth",
        kSecAttrAccount: "access-token"
    ]
    return base.merging(attributes) { $1 } as CFDictionary
}

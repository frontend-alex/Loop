import Security

enum KeychainError: Error, Equatable, Sendable {
    case osStatus(OSStatus)
    case invalidData
}

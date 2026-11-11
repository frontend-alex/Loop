nonisolated struct UserResponse: Decodable, Equatable, Sendable {
    let user: User
    let requiresOnboarding: Bool

    private enum CodingKeys: String, CodingKey {
        case user = "User"
        case requiresOnboarding
    }
}

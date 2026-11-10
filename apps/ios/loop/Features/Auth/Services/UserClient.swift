import ComposableArchitecture
import Foundation

struct UserClient: Sendable {
    var fetch: @Sendable (String) async throws -> UserResponse

    enum Failure: Error, Equatable, Sendable {
        case unauthorized
        case invalidResponse
        case httpStatus(Int)
    }

    static func live(session: URLSession, baseURL: URL) -> Self {
        Self(fetch: { token in
            guard !token.isEmpty else { throw Failure.unauthorized }

            let url = baseURL.appendingPathComponent("users").appendingPathComponent("me")
            var request = URLRequest(url: url)
            
            request.httpMethod = "GET"
            request.timeoutInterval = 20
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await session.data(for: request)
            
            guard let response = response as? HTTPURLResponse else {
                throw Failure.invalidResponse
            }
            
            if response.statusCode == 401 { throw Failure.unauthorized }
            
            guard response.statusCode == 200 else {
                throw Failure.httpStatus(response.statusCode)
            }

            let decoder = JSONDecoder()
            
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let value = try container.decode(String.self)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: value) { return date }
                formatter.formatOptions = [.withInternetDateTime]
                guard let date = formatter.date(from: value) else {
                    throw DecodingError.dataCorruptedError(
                        in: container, debugDescription: "Invalid user timestamp."
                    )
                }
                return date
            }

            return try decoder.decode(APIResponse<UserResponse>.self, from: data).data
        })
    }
}

extension UserClient: DependencyKey {
    static let liveValue = live(
        session: .shared,
        baseURL: AppEnvironment.current.apiBaseURL
    )

    static let previewValue = Self(fetch: { _ in
        UserResponse(
            user: User(
                id: 1, email: "preview@example.com", name: "Preview", avatarURL: "",
                createdAt: Date(timeIntervalSince1970: 0),
                updatedAt: Date(timeIntervalSince1970: 0)
            ),
            requiresOnboarding: true
        )
    })

    static let testValue = Self(fetch: { _ in throw Failure.invalidResponse })
}

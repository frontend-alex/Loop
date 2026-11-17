import ComposableArchitecture
import Foundation

/// The backend API. Like an axios instance with an auth interceptor: every request gets the
/// saved token from `AuthTokenStore`, and a missing token or a 401 throws `Failure.unauthorized`.
struct APIClient: Sendable {
    var fetchUser: @Sendable () async throws -> UserResponse
    var updateOnboarding: @Sendable (_ operation: OnboardingFeature.SyncOperation, _ body: OnboardingRequest) async throws -> Void

    nonisolated enum Failure: Error, Equatable, Sendable {
        case unauthorized
        case invalidResponse
        case httpStatus(Int)
    }

    static func live(session: URLSession, baseURL: URL, allowsHTTP: Bool = false) -> Self {
        @Sendable func send(_ method: String, _ path: String, body: Data? = nil, expecting status: Int) async throws -> Data {
            
            @Dependency(AuthTokenStore.self) var authTokenStore
            
            guard let token = try await authTokenStore.load(), !token.isEmpty else { throw Failure.unauthorized }
            
            guard baseURL.host != nil, baseURL.scheme == "https" || (allowsHTTP && baseURL.scheme == "http") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: baseURL.appending(path: path))
            
            request.httpMethod = method
            request.httpBody = body
            request.timeoutInterval = 20
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: body == nil ? "Accept" : "Content-Type")

            let (data, response) = try await session.data(for: request)
            
            guard let response = response as? HTTPURLResponse else { throw Failure.invalidResponse }
            
            if response.statusCode == 401 { throw Failure.unauthorized }
            guard response.statusCode == status else { throw Failure.httpStatus(response.statusCode) }
            return data
        }

        return Self(
            fetchUser: {
                let data = try await send("GET", "users/me", expecting: 200)
                return try decoder.decode(APIResponse<UserResponse>.self, from: data).data
            },
            updateOnboarding: { operation, body in
                _ = try await send("PATCH", "onboarding/\(operation.rawValue)", body: try JSONEncoder().encode(body), expecting: 204)
            }
        )
    }
}

extension APIClient: DependencyKey {
    static let liveValue = live(
        session: .shared,
        baseURL: AppEnvironment.current.apiBaseURL,
        allowsHTTP: AppEnvironment.current.isDevelopment
    )
}

private nonisolated struct APIResponse<Value: Decodable & Sendable>: Decodable, Sendable {
    let data: Value
}

/// The Go backend sends RFC 3339 timestamps with or without fractional seconds.
private nonisolated var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        let formatter = ISO8601DateFormatter()
        for options: ISO8601DateFormatter.Options in [[.withInternetDateTime, .withFractionalSeconds], [.withInternetDateTime]] {
            formatter.formatOptions = options
            if let date = formatter.date(from: value) { return date }
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid timestamp: \(value)")
    }
    return decoder
}

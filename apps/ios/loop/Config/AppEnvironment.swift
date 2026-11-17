import Foundation

nonisolated struct AppEnvironment: Sendable {
    let isDevelopment: Bool
    let apiBaseURL: URL
    let authToken: String

    static let current: AppEnvironment = {
        let info = Bundle.main.infoDictionary ?? [:]
        guard let rawURL = info["API_BASE_URL"] as? String, let apiBaseURL = URL(string: rawURL) else {
            fatalError("API_BASE_URL is missing or invalid.")
        }
        return AppEnvironment(
            isDevelopment: (info["APP_ENV"] as? String ?? "development") == "development",
            apiBaseURL: apiBaseURL,
            authToken: info["AUTH_TOKEN"] as? String ?? ""
        )
    }()
}

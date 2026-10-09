import Foundation

struct AppEnvironment: Sendable {
    enum Name: String, Sendable {
        case development
        case staging
        case production
    }

    let name: Name
    let apiBaseURL: URL

    static let current: AppEnvironment = {
        let bundle = Bundle.main
        let rawName = bundle.object(
            forInfoDictionaryKey: "APP_ENV"
        ) as? String
        let name = Name(rawValue: rawName ?? "") ?? .development

        let rawURL = bundle.object(
            forInfoDictionaryKey: "API_BASE_URL"
        ) as? String

        guard let rawURL, let apiBaseURL = URL(string: rawURL) else {
            fatalError("API_BASE_URL is missing or invalid.")
        }

        return AppEnvironment(
            name: name,
            apiBaseURL: apiBaseURL
        )
    }()
}

import Foundation

enum AuthCallbackParser {
    static func session(from callbackURL: URL) throws -> AuthSession {
        guard
            callbackURL.scheme == "loop",
            callbackURL.host == "auth",
            callbackURL.path == "/callback",
            let token = URLComponents(
                url: callbackURL,
                resolvingAgainstBaseURL: false
            )?.queryItems?.first(where: { $0.name == "token" })?.value,
            !token.isEmpty
        else {
            throw AuthClientError.invalidCallback
        }

        return AuthSession(token: token)
    }
}

import ComposableArchitecture
import Foundation
import Testing

// URLProtocol's superclass is unchecked Sendable; our only shared state is locked.
nonisolated final class OnboardingURLProtocol: URLProtocol, @unchecked Sendable {
    private static let handlers = LockIsolated<[String: @Sendable (URLRequest) -> Int]>([:])

    static func fixture(
        status: Int = 204,
        statusForRequest: (@Sendable (URLRequest) -> Int)? = nil,
        onRequest: @escaping @Sendable (URLRequest) -> Void = { _ in }
    ) throws -> (session: URLSession, baseURL: URL) {
        let host = "\(UUID().uuidString.lowercased()).invalid"
        handlers.withValue { handlers in
            handlers[host] = { request in
                onRequest(request)
                return statusForRequest?(request) ?? status
            }
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Self.self]
        let baseURL = try #require(URL(string: "https://\(host)/api/v1"))
        return (URLSession(configuration: configuration), baseURL)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host.map { handlers.value[$0] != nil } ?? false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        var request = request
        if request.httpBody == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                data.append(contentsOf: buffer.prefix(count))
            }
            request.httpBody = data
        }
        guard let url = request.url,
              let host = url.host,
              let handler = Self.handlers.value[host],
              let response = HTTPURLResponse(
                url: url,
                statusCode: handler(request),
                httpVersion: "HTTP/1.1",
                headerFields: nil
              ) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

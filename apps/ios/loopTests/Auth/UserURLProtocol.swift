import ComposableArchitecture
import Foundation
import Testing

nonisolated final class UserURLProtocol: URLProtocol, @unchecked Sendable {
    struct Stub: Sendable {
        let status: Int
        let body: Data
        let onRequest: @Sendable (URLRequest) -> Void
    }

    private static let stubs = LockIsolated<[String: Stub]>([:])

    static func session(
        status: Int = 200,
        body: Data,
        onRequest: @escaping @Sendable (URLRequest) -> Void = { _ in }
    ) throws -> (URLSession, URL) {
        let host = "\(UUID().uuidString.lowercased()).invalid"
        stubs.withValue {
            $0[host] = Stub(status: status, body: body, onRequest: onRequest)
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Self.self]
        let url = try #require(URL(string: "https://\(host)/api/v1"))
        return (URLSession(configuration: configuration), url)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host.map { stubs.value[$0] != nil } ?? false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let host = url.host,
              let stub = Self.stubs.value[host],
              let response = HTTPURLResponse(
                url: url, statusCode: stub.status, httpVersion: "HTTP/1.1", headerFields: nil
              ) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        stub.onRequest(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

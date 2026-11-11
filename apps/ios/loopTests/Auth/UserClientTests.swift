import ComposableArchitecture
import Foundation
import Testing
@testable import loop

@MainActor
struct UserClientTests {
    @Test(arguments: ["2026-11-09T12:30:00Z", "2026-11-09T12:30:00.123456789Z"])
    func decodesTheGoEnvelopeAndAuthenticatesTheRequest(timestamp: String) async throws {
        let body = Data("""
        {"data":{"User":{
          "ID":42,"Email":"alex@example.com","Name":"Alex","AvatarURL":"",
          "CreatedAt":"\(timestamp)","UpdatedAt":"\(timestamp)"
        },"requiresOnboarding":true}}
        """.utf8)
        let request = LockIsolated<URLRequest?>(nil)
        let (session, baseURL) = try UserURLProtocol.session(body: body) { request.setValue($0) }
        defer { session.invalidateAndCancel() }
        let client = UserClient.live(session: session, baseURL: baseURL)

        let response = try await client.fetch("session-token")

        #expect(response.user.id == 42)
        #expect(response.user.email == "alex@example.com")
        #expect(response.user.name == "Alex")
        #expect(response.user.avatarURL == "")
        #expect(response.user.createdAt == response.user.updatedAt)
        #expect(response.requiresOnboarding)
        let sent = try #require(request.value)
        #expect(sent.httpMethod == "GET")
        #expect(sent.url?.path == "/api/v1/users/me")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer session-token")
    }

    @Test(arguments: [401, 500])
    func nonSuccessResponsesAreNotDecodedAsUsers(status: Int) async throws {
        let (session, baseURL) = try UserURLProtocol.session(status: status, body: Data())
        defer { session.invalidateAndCancel() }
        let client = UserClient.live(session: session, baseURL: baseURL)

        let error = await #expect(throws: UserClient.Failure.self) {
            try await client.fetch("session-token")
        }
        #expect(error == (status == 401 ? .unauthorized : .httpStatus(status)))
    }

    @Test func missingOnboardingFlagIsAnErrorRatherThanADefaultRoute() async throws {
        let body = Data("""
        {"data":{"User":{
          "ID":42,"Email":"alex@example.com","Name":"Alex","AvatarURL":"",
          "CreatedAt":"2026-11-09T12:30:00Z","UpdatedAt":"2026-11-09T12:30:00Z"
        }}}
        """.utf8)
        let (session, baseURL) = try UserURLProtocol.session(body: body)
        defer { session.invalidateAndCancel() }
        let client = UserClient.live(session: session, baseURL: baseURL)

        await #expect(throws: DecodingError.self) {
            try await client.fetch("session-token")
        }
    }
}

import ComposableArchitecture
import FamilyControls

struct AppBlockingClient: Sendable, DependencyKey {
    var requestAuthorization: @Sendable () async throws -> Bool

    static let liveValue = Self(
        requestAuthorization: { @MainActor in
            #if DEBUG
            // Family Controls needs a distribution entitlement; debug builds pretend access was granted.
            return true
            #else
            let center = AuthorizationCenter.shared
            if center.authorizationStatus != .approved {
                try await center.requestAuthorization(for: .individual)
            }
            return center.authorizationStatus == .approved
            #endif
        }
    )
}

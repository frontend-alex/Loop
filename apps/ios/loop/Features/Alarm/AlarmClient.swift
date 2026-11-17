import ActivityKit
import AlarmKit
import ComposableArchitecture
import SwiftUI

struct AlarmClient: Sendable, DependencyKey {
    var authorizationStatus: @Sendable () async -> PermissionStatus
    /// Shows the system prompt if needed; any failure counts as denied.
    var requestAuthorization: @Sendable () async -> PermissionStatus
    /// Schedules a one-off alarm, cancelling `replacing` if it is still scheduled.
    var schedule: @Sendable (_ date: Date, _ replacing: UUID?) async throws -> UUID

    static let liveValue = Self(
        authorizationStatus: { PermissionStatus(AlarmManager.shared.authorizationState) },
        requestAuthorization: {
            (try? await AlarmManager.shared.requestAuthorization()).map(PermissionStatus.init) ?? .denied
        },
        schedule: { date, previousID in
            let manager = AlarmManager.shared
            if let previousID, try manager.alarms.contains(where: { $0.id == previousID }) {
                try manager.cancel(id: previousID)
            }
            let id = UUID()
            _ = try await manager.schedule(
                id: id,
                configuration: AlarmManager.AlarmConfiguration<LoopAlarmMetadata>(
                    schedule: .fixed(date),
                    attributes: AlarmAttributes(
                        presentation: AlarmPresentation(alert: .init(title: "Alarm")),
                        metadata: LoopAlarmMetadata(),
                        tintColor: .orange
                    ),
                    sound: .default
                )
            )
            return id
        }
    )
}

nonisolated struct LoopAlarmMetadata: AlarmMetadata {}

private nonisolated extension PermissionStatus {
    init(_ state: AlarmManager.AuthorizationState) {
        switch state {
        case .notDetermined: self = .unknown
        case .authorized: self = .authorized
        default: self = .denied
        }
    }
}

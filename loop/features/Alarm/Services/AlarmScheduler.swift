//
//  AlarmScheduler.swift
//  loop
//
//  Created by Aleksander Ivanov on 05/09/2026.
//

import AlarmKit
import Foundation
import SwiftUI
import ActivityKit


struct AlarmKitMetadata: AlarmMetadata {}


enum AlarmScheduler {
    static func setAlarm(at date: Date) async throws -> UUID {
        let id = UUID();
        
        let alert = AlarmPresentation.Alert(
            title: "Alarm"
        )
        
        let presentation = AlarmPresentation(
            alert: alert
        )
        
        let attributes = AlarmAttributes<AlarmKitMetadata>(
            presentation: presentation,
            metadata: AlarmKitMetadata(),
            tintColor: .orange
        )
        
        let configuration = AlarmManager.AlarmConfiguration<AlarmKitMetadata>(
            schedule: .fixed(date),
            attributes: attributes,
            sound: .default
        )
        
        _ = try await AlarmManager.shared.schedule(
            id: id,
            configuration: configuration
        )
        
        return id;
    }
    
    static func cancelAlarm(id: UUID) async throws {
        let alarms = try AlarmManager.shared.alarms
        
        guard alarms.contains(where: { $0.id == id }) else {
            print("Previous alarm no longer exists:", id)
            return
        }
        
        try await AlarmManager.shared.cancel(id: id)
        print("Previous alarm cancelled:", id)
    }
}

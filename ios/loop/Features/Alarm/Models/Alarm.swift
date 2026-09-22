//
//  Alarm.swift
//  loop
//
//  Created by Aleksander Ivanov on 15/09/2026.
//
import Foundation

enum AlarmWeekday: String, CaseIterable, Codable, Hashable, Identifiable {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }
}

enum AlarmSound: String, CaseIterable, Codable, Hashable, Identifiable {
    case `default`
    case radar
    case birds

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }
}

extension Alarm {
    var repeatSummary: String {
        if repeatDays.isEmpty {
            return "Never"
        }

        if repeatDays == Set(AlarmWeekday.allCases) {
            return "Every Day"
        }

        return repeatDays
            .sorted { $0.id.rawValue < $1.id.rawValue }
            .map(\.title)
            .joined(separator: ", ")
    }
}

struct Alarm: Equatable, Codable, Sendable {
    var scheduledID: UUID?
    var time: Date
    var isRepeating: Bool
    var repeatDays: Set<AlarmWeekday>
    var label: String;
    var sound: AlarmSound;
    var snoozeEnabled: Bool;
}

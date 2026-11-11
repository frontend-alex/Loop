//
//  Alarm.swift
//  loop
//
//  Created by Aleksander Ivanov on 15/09/2026.
//
import Foundation

nonisolated enum AlarmWeekday: String, CaseIterable, Codable, Hashable, Identifiable {
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

nonisolated enum AlarmSound: String, CaseIterable, Codable, Hashable, Identifiable {
    case `default`
    case radar
    case birds

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }
}

extension Alarm {
    func nextOccurrence(after now: Date, calendar: Calendar = .current) -> Date? {
        var components = calendar.dateComponents([.hour, .minute], from: time)
        components.second = 0

        return calendar.nextDate(
            after: now,
            matching: components,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        )
    }

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

nonisolated struct Alarm: Equatable, Codable, Sendable {
    var scheduledID: UUID?
    var time: Date
    var isRepeating: Bool
    var repeatDays: Set<AlarmWeekday>
    var label: String;
    var sound: AlarmSound;
    var snoozeEnabled: Bool;
}

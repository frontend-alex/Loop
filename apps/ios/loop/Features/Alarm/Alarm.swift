import Foundation

nonisolated struct Alarm: Equatable, Codable, Sendable {
    var scheduledID: UUID?
    var time = Date.now
    var repeatDays: Set<AlarmWeekday> = []
    var label = ""
    var sound = AlarmSound.default
    var snoozeEnabled = true

    var isRepeating: Bool { !repeatDays.isEmpty }

    func nextOccurrence(after now: Date, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.hour, .minute], from: time)
        components.second = 0
        return calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)
    }
}

nonisolated enum AlarmWeekday: String, CaseIterable, Codable, Hashable, Identifiable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Self { self }
    var title: String { rawValue.capitalized }
}

nonisolated enum AlarmSound: String, CaseIterable, Codable, Hashable, Identifiable {
    case `default`, radar, birds

    var id: Self { self }
    var title: String { rawValue.capitalized }
}

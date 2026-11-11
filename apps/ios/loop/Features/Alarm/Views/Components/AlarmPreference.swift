enum AlarmPreference: Identifiable {
    case sound
    case snooze
    case repeatDays

    var id: Self { self }

    var title: String {
        switch self {
        case .sound: "Sound"
        case .snooze: "Snooze"
        case .repeatDays: "Repeat"
        }
    }
}

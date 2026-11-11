import SwiftUI

struct AlarmPreferences: View {
    @Binding var alarm: Alarm
    @State private var drawer: AlarmPreference?

    private var repeatSummary: String {
        if alarm.repeatDays.isEmpty { return "No" }
        if alarm.repeatDays.count == AlarmWeekday.allCases.count { return "Every day" }
        return "\(alarm.repeatDays.count) days"
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            AlarmPreferenceButton(title: "Sound", systemImage: "music.note", summary: alarm.sound.title) {
                drawer = .sound
            }
            AlarmPreferenceButton(
                title: "Snooze", systemImage: "bell", summary: alarm.snoozeEnabled ? "On" : "Off"
            ) {
                drawer = .snooze
            }
            AlarmPreferenceButton(
                title: "Repeat", systemImage: "repeat", summary: repeatSummary,
                isActive: !alarm.repeatDays.isEmpty
            ) {
                drawer = .repeatDays
            }
            .accessibilityValue(alarm.repeatSummary)
        }
        .sheet(item: $drawer) { preference in
            AlarmSettingsDrawer(title: preference.title) {
                switch preference {
                case .sound:
                    AlarmSoundDrawer(selection: $alarm.sound)
                case .snooze:
                    AlarmSnoozeDrawer(isEnabled: $alarm.snoozeEnabled)
                case .repeatDays:
                    AlarmRepeatView(selectedDays: $alarm.repeatDays)
                }
            }
        }
        .onChange(of: alarm.repeatDays) {
            alarm.isRepeating = !alarm.repeatDays.isEmpty
        }
    }
}

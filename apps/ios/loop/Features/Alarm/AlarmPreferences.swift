import ComposableArchitecture
import SwiftUI

/// Sound, snooze and repeat as round glass buttons the size of the onboarding arrow.
/// Snooze toggles in place; sound and repeat open a sheet.
struct AlarmPreferences: View {
    @Bindable var store: StoreOf<AlarmFeature>
    @State private var sheet: Sheet?

    private enum Sheet: String, Identifiable {
        case sound = "Sound", repeatDays = "Repeat"
        var id: Self { self }
    }

    private var alarm: Alarm { store.alarm }

    private var repeatSummary: String {
        switch alarm.repeatDays.count {
        case 0: "Never"
        case AlarmWeekday.allCases.count: "Every day"
        case let count: "\(count) days"
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconButton(title: "Sound", systemImage: "music.note", value: alarm.sound.title) {
                sheet = .sound
            }
            IconButton(title: "Snooze", systemImage: "bell", value: alarm.snoozeEnabled ? "On" : "Off", isOn: alarm.snoozeEnabled) {
                store.alarm.snoozeEnabled.toggle()
            }
            .accessibilityAddTraits(.isToggle)
            .sensoryFeedback(.selection, trigger: alarm.snoozeEnabled)
            IconButton(title: "Repeat", systemImage: "repeat", value: repeatSummary, isOn: alarm.isRepeating) {
                sheet = .repeatDays
            }
        }
        .sheet(item: $sheet) { sheet in
            SettingsSheet(title: sheet.rawValue) {
                switch sheet {
                case .sound:
                    List(AlarmSound.allCases) { sound in
                        Button {
                            store.alarm.sound = sound
                        } label: {
                            LabeledContent(sound.title) {
                                if alarm.sound == sound { Image(systemName: "checkmark") }
                            }
                            .frame(minHeight: 44)
                            .contentShape(.rect)
                        }
                        .accessibilityAddTraits(alarm.sound == sound ? .isSelected : [])
                    }
                case .repeatDays:
                    List(AlarmWeekday.allCases) { day in
                        Toggle(day.title, isOn: Binding {
                            alarm.repeatDays.contains(day)
                        } set: { isOn in
                            if isOn { store.alarm.repeatDays.insert(day) } else { store.alarm.repeatDays.remove(day) }
                        })
                    }
                }
            }
        }
    }
}

/// A round icon button styled like the onboarding arrow; filled when its setting is on.
private struct IconButton: View {
    let title: String
    let systemImage: String
    let value: String
    var isOn = false
    let action: () -> Void

    var body: some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .buttonStyle(isOn
                ? .app(size: .largeIcon, tint: .foregroundPrimary, foreground: .foregroundInverse)
                : .app(.secondary, size: .largeIcon))
            .animation(.easeInOut(duration: 0.2), value: isOn)
            .accessibilityValue(value)
    }
}

private struct SettingsSheet<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .tint(.textPrimary)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

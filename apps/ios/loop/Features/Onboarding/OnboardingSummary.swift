import ComposableArchitecture
import FamilyControls
import SwiftUI

/// The last onboarding step's page: the alarm on the same dials as the alarm step, read-only.
struct OnboardingSummary: View {
    let store: StoreOf<OnboardingFeature>

    @Environment(\.calendar) private var calendar

    private var alarmTime: String {
        let time = calendar.dateComponents([.hour, .minute], from: store.alarm.alarm.time)
        return String(format: "%02d:%02d", time.hour ?? 0, time.minute ?? 0)
    }

    var body: some View {
        ClockTimePicker(selection: .constant(store.alarm.alarm.time), isReadOnly: true)
            .padding(.horizontal, -Spacing.lg)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Alarm at \(alarmTime)")
    }
}

/// The summary's recap, beside Finish in the bottom bar like the alarm preferences beside the
/// arrow, so the summary dial gets the same room as the other dials. Each jumps back to its step.
struct SummaryShortcuts: View {
    let store: StoreOf<OnboardingFeature>

    private var lockedCount: Int {
        let selection = store.appBlocking.selection
        return selection.categoryTokens.count + selection.applicationTokens.count
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            shortcut("Locked apps", systemImage: "lock.fill", count: lockedCount, step: .apps)
            shortcut("Wake-up Tasks", systemImage: "sun.max.fill", count: store.selectedTaskIDs.count, step: .tasks)
        }
    }

    private func shortcut(_ title: String, systemImage: String, count: Int, step: OnboardingStep) -> some View {
        Button { store.send(.editTapped(step), animation: .smooth(duration: 0.4)) } label: {
            Label("\(count)", systemImage: systemImage)
                .lineLimit(1)
                .frame(minHeight: 56 - Spacing.lg * 2) // As tall as the round buttons beside it.
        }
        .buttonStyle(.app(.secondary))
        .accessibilityLabel("\(title), \(count)")
        .accessibilityHint("Change")
    }
}

import SwiftUI

/// A controlled, 24-hour time picker. Each half is an independently rotating dial.
struct ClockTimePicker: View {
    @Binding var selection: Date

    @Environment(\.calendar) private var calendar
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var hours: Binding<Int> {
        Binding(
            get: { calendar.component(.hour, from: selection) },
            set: { setTime(hour: $0, minute: calendar.component(.minute, from: selection)) }
        )
    }

    private var minutes: Binding<Int> {
        Binding(
            get: { calendar.component(.minute, from: selection) },
            set: { setTime(hour: calendar.component(.hour, from: selection), minute: $0) }
        )
    }

    var body: some View {
        GeometryReader { geometry in
            if dynamicTypeSize.isAccessibilitySize {
                DatePicker("Time", selection: $selection, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if geometry.size.height < 240 {
                DatePicker("Time", selection: $selection, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: DesignSystem.Spacing.lg) {
                    ClockWheel(value: hours, count: 24, label: "Hours, 24-hour clock", isMirrored: false)
                    ClockWheel(value: minutes, count: 60, label: "Minutes", isMirrored: true)
                }
                .clipped()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("clock-time-picker")
    }

    private func setTime(hour: Int, minute: Int) {
        guard let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selection) else {
            return
        }
        selection = date
    }
}

#Preview("Two-circle clock") {
    @Previewable @State var time = Calendar.current.date(
        bySettingHour: 10, minute: 50, second: 0, of: .now
    ) ?? .now

    ClockTimePicker(selection: $time)
        .frame(height: 560)
}

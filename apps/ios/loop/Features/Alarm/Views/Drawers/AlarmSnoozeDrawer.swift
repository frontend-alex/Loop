import SwiftUI

struct AlarmSnoozeDrawer: View {
    @Binding var isEnabled: Bool

    var body: some View {
        Form {
            Toggle("Snooze", isOn: $isEnabled)
                .frame(minHeight: 44)
        }
    }
}

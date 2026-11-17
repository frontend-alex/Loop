import ComposableArchitecture
import SwiftUI

/// The alarm clock. Saving and the preference buttons belong to the screen that hosts it.
struct AlarmView: View {
    @Bindable var store: StoreOf<AlarmFeature>

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ClockTimePicker(selection: $store.alarm.time)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, -Spacing.lg)
                .accessibilityLabel("Alarm time")
                .onAppear { store.send(.appeared) }

            if let message = store.errorMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.danger)
                    .multilineTextAlignment(.center)
            }
        }
        .disabled(store.isSaving)
        .task { store.send(.authorizationRefreshed) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.authorizationRefreshed) }
        }
    }
}

#Preview {
    AlarmView(store: Store(initialState: AlarmFeature.State(authorizationStatus: .authorized)) { AlarmFeature() })
        .safeAreaPadding(.horizontal, Spacing.lg)
}

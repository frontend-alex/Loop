import ComposableArchitecture
import SwiftUI

struct AlarmSetupActions: View {
    let store: StoreOf<AlarmProvider>
    let isEnabled: Bool
    let setAlarm: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassNamespace

    var body: some View {
        GlassEffectContainer(spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.lg) {
                AppButton(action: setAlarm) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if store.isSaving {
                            ProgressView()
                        }
                        Text("Set Alarm")
                    }
                }
                .disabled(store.authorizationStatus != .authorized)
                .accessibilityIdentifier("set-alarm")
                .glassEffectID("set-alarm", in: glassNamespace)

                if store.canSkipSetup {
                    AppButton(variant: .secondary, size: .large, fullWidth: false) {
                        store.send(.skipTapped)
                    } label: {
                        Label("Skip alarm setup", systemImage: "forward.end.fill")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityIdentifier("skip-alarm-setup")
                    .glassEffectID("skip-alarm", in: glassNamespace)
                    .glassEffectTransition(.matchedGeometry)
                }
            }
        }
        .animation(
            reduceMotion ? nil : DesignSystem.Motion.transition,
            value: store.canSkipSetup
        )
        .disabled(!isEnabled || store.isSaving)
    }
}

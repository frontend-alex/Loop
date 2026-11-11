import SwiftUI
import ComposableArchitecture

struct OnboardingSummary: View {
    let store: StoreOf<OnboardingProvider>

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.XXXL) {
                OnboardingHeading(
                    title: "Your setup",
                    subtitle: "Review your preferences before continuing."
                )

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.XXL) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Alarm").font(.headline)
                        if store.alarm.alarm.scheduledID != nil {
                            Text(store.alarm.alarm.time, style: .time)
                                .foregroundStyle(DesignSystem.Semantic.textSecondary)
                        } else {
                            Text("Set an alarm when you're ready")
                                .foregroundStyle(DesignSystem.Semantic.textSecondary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("App blocking").font(.headline)
                        Text(store.appBlocking.authorizationStatus == .authorized
                             ? "App blocking access enabled"
                             : "You can enable app blocking later")
                            .foregroundStyle(DesignSystem.Semantic.textSecondary)
                    }
                }
                .padding(DesignSystem.Spacing.XXL)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.Semantic.surfacePrimary, in: RoundedRectangle(cornerRadius: 24))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(DesignSystem.Semantic.borderDefault)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.XXL)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

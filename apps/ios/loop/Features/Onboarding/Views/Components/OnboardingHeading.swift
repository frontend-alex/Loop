import SwiftUI

struct OnboardingHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(.title.bold())
                .foregroundStyle(DesignSystem.Semantic.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(DesignSystem.Semantic.textSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }
}

import SwiftUI

/// The one heading every onboarding step uses: Title 2, the same everywhere.
/// List steps read left-aligned at the heading's natural height. Dial steps center it and
/// reserve two title lines, bottom-aligned so it hugs the dial, so every dial is the same size
/// whether its title takes one line or two.
struct OnboardingHeading: View {
    let title: String
    var subtitle = ""
    var isForDial = false

    @ScaledMetric(relativeTo: .title2) private var twoLines: CGFloat = 58

    var body: some View {
        VStack(alignment: isForDial ? .center : .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.textPrimary)
                .accessibilityAddTraits(.isHeader)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
            }
        }
        .multilineTextAlignment(isForDial ? .center : .leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(
            maxWidth: .infinity,
            minHeight: isForDial ? twoLines : nil,
            alignment: isForDial ? .bottom : .leading
        )
    }
}

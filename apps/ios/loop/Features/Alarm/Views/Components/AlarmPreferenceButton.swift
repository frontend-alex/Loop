import SwiftUI

/// The compact icon/title/value treatment in the clock reference, not a form row.
struct AlarmPreferenceButton: View {
    let title: String
    let systemImage: String
    let summary: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundStyle(
                        isActive
                            ? DesignSystem.Semantic.buttonPrimaryForeground
                            : DesignSystem.Semantic.textPrimary
                    )
                    .frame(width: 32, height: 32)
                    .background {
                        if isActive {
                            Circle().fill(DesignSystem.Semantic.buttonPrimaryTint)
                        }
                    }

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DesignSystem.Semantic.textPrimary)

                Text(summary)
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Semantic.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(summary)
        .accessibilityHint("Opens settings")
    }
}

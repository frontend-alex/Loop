import SwiftUI

struct OnboardingOptionCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(isSelected ? .semibold : .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(DesignSystem.Semantic.textPrimary)
                .padding(DesignSystem.Spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    isSelected
                        ? DesignSystem.Palette.brand500.opacity(0.14)
                        : DesignSystem.Semantic.backgroundSecondary,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? DesignSystem.Palette.brand500 : .clear,
                            lineWidth: 2
                        )
                }
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

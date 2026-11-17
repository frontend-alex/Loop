import SwiftUI

/// A full-width capsule choice. Selected options invert to solid black; a ✓ marks them when
/// more than one can be picked.
struct OptionButton<Label: View>: View {
    let isSelected: Bool
    var showsCheckmark = true
    var size = AppButtonStyle.Size.regular
    let action: () -> Void
    @ViewBuilder let label: Label

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                label
                Spacer(minLength: Spacing.md)
                if showsCheckmark && isSelected {
                    Image(systemName: "checkmark").accessibilityHidden(true)
                }
            }
            .multilineTextAlignment(.leading)
        }
        .buttonStyle(isSelected
            ? .app(size: size, tint: .foregroundPrimary, foreground: .foregroundInverse)
            : .app(.secondary, size: size))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

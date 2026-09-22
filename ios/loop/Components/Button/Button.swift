import SwiftUI

// MARK: - Variants

enum AppButtonVariant {
    case primary
    case secondary
    case muted
    case ghost
    case link
    case destructive

    var foreground: Color {
        switch self {
        case .primary:
            DesignSystem.Semantic.buttonPrimaryForeground
        case .secondary:
            DesignSystem.Semantic.buttonSecondaryForeground
        case .muted:
            DesignSystem.Semantic.buttonMutedForeground
        case .ghost, .link:
            DesignSystem.Semantic.buttonGhostForeground
        case .destructive:
            DesignSystem.Semantic.buttonDangerForeground
        }
    }

    var background: Color {
        switch self {
        case .primary:
            DesignSystem.Semantic.buttonPrimaryTint
        case .secondary:
            DesignSystem.Semantic.buttonSecondaryTint
        case .muted:
            DesignSystem.Semantic.buttonMutedTint
        case .destructive:
            DesignSystem.Semantic.buttonDangerTint
        case .ghost, .link:
            .clear
        }
    }

    var hasBackground: Bool {
        switch self {
        case .ghost, .link:
            false
        default:
            true
        }
    }
}

// MARK: - Sizes

enum AppButtonSize {
    case small
    case medium
    case large
    case iconSmall
    case iconMedium
    case iconLarge

    var isIcon: Bool {
        switch self {
        case .iconSmall, .iconMedium, .iconLarge:
            true
        default:
            false
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small, .iconSmall:
            15
        case .medium, .large, .iconMedium, .iconLarge:
            17
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small:
            10
        case .medium:
            DesignSystem.Spacing.md
        case .large:
            DesignSystem.Spacing.xl
        case .iconSmall, .iconMedium, .iconLarge:
            0
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small:
            5
        case .medium:
            DesignSystem.Spacing.sm
        case .large:
            DesignSystem.Spacing.lg
        case .iconSmall, .iconMedium, .iconLarge:
            0
        }
    }

    var minimumHeight: CGFloat {
        switch self {
        case .small:
            28
        case .medium:
            34
        case .large:
            50
        case .iconSmall:
            44
        case .iconMedium:
            48
        case .iconLarge:
            56
        }
    }
}

// MARK: - Component

struct AppButton<Label: View>: View {
    private let variant: AppButtonVariant
    private let size: AppButtonSize
    private let fullWidth: Bool
    private let backgroundColor: Color?
    private let foregroundColor: Color?
    private let action: () -> Void
    private let label: Label

    init(
        variant: AppButtonVariant = .primary,
        size: AppButtonSize = .large,
        fullWidth: Bool = true,
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.variant = variant
        self.size = size
        self.fullWidth = fullWidth
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(
            role: variant == .destructive ? .destructive : nil,
            action: action
        ) {
            label
        }
        .buttonStyle(
            AppButtonStyle(
                variant: variant,
                size: size,
                fullWidth: fullWidth,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor
            )
        )
    }
}

// MARK: - Text Convenience Initializer

extension AppButton where Label == Text {
    init(
        _ title: LocalizedStringKey,
        variant: AppButtonVariant = .primary,
        size: AppButtonSize = .large,
        fullWidth: Bool = true,
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.init(
            variant: variant,
            size: size,
            fullWidth: fullWidth,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            action: action
        ) {
            Text(title)
        }
    }
}

// MARK: - Shared Styling

struct AppButtonStyle: ButtonStyle {
    var variant: AppButtonVariant = .primary
    var size: AppButtonSize = .large
    var fullWidth: Bool = true
    var backgroundColor: Color? = nil
    var foregroundColor: Color? = nil

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(
            label: configuration.label,
            variant: variant,
            size: size,
            fullWidth: fullWidth,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            isEnabled: isEnabled,
            isPressed: configuration.isPressed
        )
    }

    private struct StyledLabel: View {
        let label: ButtonStyleConfiguration.Label
        let variant: AppButtonVariant
        let size: AppButtonSize
        let fullWidth: Bool
        let backgroundColor: Color?
        let foregroundColor: Color?
        let isEnabled: Bool
        let isPressed: Bool

        @ScaledMetric(relativeTo: .body)
        private var textScale: CGFloat = 1

        private var hasBackground: Bool {
            backgroundColor != nil || variant.hasBackground
        }

        private var foreground: Color {
            isEnabled
                ? (foregroundColor ?? variant.foreground)
                : DesignSystem.Semantic.buttonDisabledForeground
        }

        private var background: Color {
            guard hasBackground else {
                return .clear
            }

            return isEnabled
                ? (backgroundColor ?? variant.background)
                : DesignSystem.Semantic.buttonDisabledTint
        }

        private var iconDimension: CGFloat {
            max(
                size.minimumHeight,
                size.fontSize * textScale + DesignSystem.Spacing.lg
            )
        }

        var body: some View {
            surface
                .contentShape(Capsule())
                .opacity(isPressed && isEnabled ? 0.7 : 1)
        }

        @ViewBuilder
        private var surface: some View {
            if hasBackground {
                styledContent
                    .glassEffect(
                        .regular
                            .tint(background)
                            .interactive(),
                        in: Capsule()
                    )
            } else {
                styledContent
            }
        }

        private var styledContent: some View {
            label
                .font(
                    .system(
                        size: size.fontSize * textScale,
                        weight: .medium
                    )
                )
                .foregroundStyle(foreground)
                .underline(variant == .link)
                .padding(.horizontal, size.horizontalPadding)
                .padding(.vertical, size.verticalPadding)
                .frame(
                    minWidth: size.isIcon ? iconDimension : nil,
                    maxWidth: size.isIcon
                        ? iconDimension
                        : (fullWidth ? .infinity : nil),
                    minHeight: size.isIcon
                        ? iconDimension
                        : size.minimumHeight
                )
        }
    }
}

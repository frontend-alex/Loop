import SwiftUI

/// Loop's Liquid Glass capsule button. Use as `.buttonStyle(.app)` or `.buttonStyle(.app(.secondary))`.
struct AppButtonStyle: ButtonStyle {
    enum Variant { case primary, secondary, ghost }
    enum Size { case regular, icon, largeIcon }

    var variant = Variant.primary
    var size = Size.regular
    var tint: Color?
    var foreground: Color?

    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration, style: self)
    }

    private struct StyledLabel: View {
        let configuration: Configuration
        let style: AppButtonStyle

        @Environment(\.isEnabled) private var isEnabled
        @ScaledMetric private var scale: CGFloat = 1

        private var fontSize: CGFloat { style.size == .icon ? 15 : 17 }

        private var iconDimension: CGFloat? {
            switch style.size {
            case .regular: nil
            case .icon: max(44, fontSize * scale + Spacing.lg)
            case .largeIcon: max(56, fontSize * scale + Spacing.lg)
            }
        }

        private var foreground: Color {
            guard isEnabled else { return Color("LoopSemantic-Button-Disabled-Foreground") }
            if let foreground = style.foreground { return foreground }
            return switch style.variant {
            case .primary: Color("LoopSemantic-Button-Primary-Foreground")
            case .secondary: Color("LoopSemantic-Button-Secondary-Foreground")
            case .ghost: Color("LoopSemantic-Button-Ghost-Foreground")
            }
        }

        private var background: Color {
            guard isEnabled else { return Color("LoopSemantic-Button-Disabled-Tint") }
            if let tint = style.tint { return tint }
            return switch style.variant {
            case .primary: Color("LoopSemantic-Button-Primary-Tint")
            case .secondary: Color("LoopSemantic-Button-Secondary-Tint")
            case .ghost: .clear
            }
        }

        var body: some View {
            let label = configuration.label
                .font(.system(size: fontSize * scale, weight: .medium))
                .foregroundStyle(foreground)
                .padding(.horizontal, iconDimension == nil ? Spacing.xl : 0)
                .padding(.vertical, iconDimension == nil ? Spacing.lg : 0)
                .frame(
                    minWidth: iconDimension,
                    maxWidth: iconDimension ?? .infinity,
                    minHeight: iconDimension ?? 50
                )
                .contentShape(.capsule)
                .opacity(configuration.isPressed && isEnabled ? 0.7 : 1)

            if style.variant == .ghost && style.tint == nil {
                label
            } else {
                label.glassEffect(.regular.tint(background).interactive(), in: .capsule)
            }
        }
    }
}

extension ButtonStyle where Self == AppButtonStyle {
    static var app: Self { AppButtonStyle() }

    static func app(
        _ variant: AppButtonStyle.Variant = .primary,
        size: AppButtonStyle.Size = .regular,
        tint: Color? = nil,
        foreground: Color? = nil
    ) -> Self {
        AppButtonStyle(variant: variant, size: size, tint: tint, foreground: foreground)
    }
}

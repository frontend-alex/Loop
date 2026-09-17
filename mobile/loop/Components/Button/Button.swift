//
//  Button.swift
//  loop
//
//  Created by Aleksander Ivanov on 15/09/2026.
//
import SwiftUI

enum AppButtonVariant {
    case primary
    case secondary
    case ghost
    case destructive
    case link
    case icon
}

enum AppButtonSize {
    case small
    case medium
    case large

    var font: Font {
        switch self {
        case .small:
            .footnote
        case .medium:
            .body
        case .large:
            .headline
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small:
            12
        case .medium:
            16
        case .large:
            20
        }
    }

    var minimumHeight: CGFloat {
        switch self {
        case .small:
            44
        case .medium:
            48
        case .large:
            56
        }
    }

    var iconDimension: CGFloat {
        switch self {
        case .small:
            44
        case .medium:
            48
        case .large:
            56
        }
    }
}

enum AppButtonWidth {
    case automatic
    case fit
    case fill
}

enum AppButtonBackground {
    case automatic
    case none
    case color(Color)
}

struct AppButton<Label: View>: View {
    let variant: AppButtonVariant
    let size: AppButtonSize
    let width: AppButtonWidth
    let tint: Color?
    let background: AppButtonBackground
    let action: () -> Void
    let label: () -> Label

    init(
        variant: AppButtonVariant = .primary,
        size: AppButtonSize = .medium,
        width: AppButtonWidth = .automatic,
        tint: Color? = nil,
        background: AppButtonBackground = .automatic,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.variant = variant
        self.size = size
        self.width = width
        self.tint = tint
        self.background = background
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(
            role: variant == .destructive ? .destructive : nil,
            action: action
        ) {
            label()
        }
        .buttonStyle(
            AppButtonStyle(
                variant: variant,
                size: size,
                width: width,
                tint: tint,
                background: background
            )
        )
    }
}

struct AppButtonStyle: ButtonStyle {
    let variant: AppButtonVariant
    let size: AppButtonSize
    let width: AppButtonWidth
    let tint: Color?
    let background: AppButtonBackground

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundStyle(tint ?? variant.defaultTint)
            .underline(variant == .link)
            .padding(.horizontal, variant == .icon ? 0 : size.horizontalPadding)
            .frame(
                minWidth: variant == .icon ? size.iconDimension : nil,
                maxWidth: resolvedWidth,
                minHeight: variant == .icon ? size.iconDimension : size.minimumHeight
            )
            .background {
                backgroundView
            }
            .modifier(AppButtonGlassEffect(variant: variant))
            .opacity(
                isEnabled
                    ? configuration.isPressed ? 0.7 : 1
                    : 0.45
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    private var resolvedWidth: CGFloat? {
        switch width {
        case .fill:
            .infinity
        case .fit:
            nil
        case .automatic:
            variant.defaultWidth == .fill ? .infinity : nil
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if let color = resolvedBackground {
            if variant == .icon {
                Circle()
                    .fill(color)
            } else {
                Capsule()
                    .fill(color)
            }
        }
    }

    private var resolvedBackground: Color? {
        guard variant != .ghost else { return nil }

        switch background {
        case .automatic:
            return variant.defaultBackground
        case .none:
            return nil
        case let .color(color):
            return color
        }
    }
}

private struct AppButtonGlassEffect: ViewModifier {
    let variant: AppButtonVariant

    @ViewBuilder
    func body(content: Content) -> some View {
        if variant == .ghost {
            content
        } else if variant == .icon {
            content
                .glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .glassEffect(.regular.interactive(), in: Capsule())
        }
    }
}

private extension AppButtonVariant {
    var defaultTint: Color {
        switch self {
        case .primary, .destructive:
            .white
        case .secondary, .ghost, .link, .icon:
            .orange
        }
    }

    var defaultBackground: Color? {
        switch self {
        case .primary:
            .orange
        case .secondary:
            .orange.opacity(0.15)
        case .destructive:
            .red
        case .ghost, .link, .icon:
            nil
        }
    }

    var defaultWidth: AppButtonWidth {
        switch self {
        case .primary, .secondary, .destructive:
            .fill
        case .ghost, .link, .icon:
            .fit
        }
    }
}

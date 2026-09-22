//
//  NotificationsPremission.swift
//  loop
//
//  Created by Aleksander Ivanov on 18/09/2026.
//
import SwiftUI

struct NotificationsPremission: View {
    var tint: Color = .orange

    var title: String
    var description: String

    var primaryActionTitle: String
    var secondaryActionTitle: String
    var isPrimaryActionEnabled: Bool = true

    var primaryAction: () -> Void
    var secondaryAction: () -> Void

    @State private var showPermissionAnimation = false

    var body: some View {
        PermissionScreen(
            tint: tint,
            title: title,
            description: description,
            primaryActionTitle: primaryActionTitle,
            secondaryActionTitle: secondaryActionTitle,
            isPrimaryActionEnabled: isPrimaryActionEnabled,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction
        ) {
            if showPermissionAnimation {
                animatedAlertView()
            }
        }
        .task {
            guard !showPermissionAnimation else { return }
            try? await Task.sleep(for: .seconds(0.5))
            showPermissionAnimation = true
        }
    }

    @ViewBuilder
    private func animatedAlertView() -> some View {
        let fill = Color.primary.opacity(0.15)

        KeyframeAnimator(initialValue: AlertFrame(), repeating: true) { frame in
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm - 2) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(fill)
                    .frame(width: 120, height: 20)
                    .padding(.bottom, 12)

                RoundedRectangle(cornerRadius: 3)
                    .fill(fill)
                    .frame(height: 15)

                RoundedRectangle(cornerRadius: 3)
                    .fill(fill)
                    .frame(height: 15)
                    .padding(.trailing, 50)
                    .padding(.bottom, 30)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(1...2, id: \.self) { index in
                        Capsule()
                            .fill(fill)
                            .frame(height: 45)
                            .overlay {
                                if index == 2 {
                                    Circle()
                                        .fill(.gray.opacity(0.8))
                                        .padding(5)
                                        .opacity(frame.tapOpacity)
                                }
                            }
                            .scaleEffect(index == 2 ? frame.tapScale : 1)
                    }
                }
            }
            .frame(width: 280)
            .padding(20)
            .optionalLiquidGlass()
            .opacity(frame.opacity)
            .scaleEffect(frame.scale)
        } keyframes: { _ in
            SpringKeyframe(
                AlertFrame(opacity: 1, scale: 1),
                duration: 0.7,
                spring: .smooth(duration: 0.5, extraBounce: 0)
            )
            SpringKeyframe(
                AlertFrame(opacity: 1, scale: 1, tapOpacity: 1),
                duration: 0.1,
                spring: .smooth(duration: 0.4, extraBounce: 0)
            )
            SpringKeyframe(
                AlertFrame(opacity: 1, scale: 1, tapOpacity: 1, tapScale: 0.9),
                duration: 0.2,
                spring: .smooth(duration: 0.4, extraBounce: 0)
            )
            SpringKeyframe(
                AlertFrame(opacity: 1, scale: 1),
                duration: 0.4,
                spring: .smooth(duration: 0.4, extraBounce: 0)
            )
            SpringKeyframe(
                AlertFrame(),
                duration: 2,
                spring: .smooth(duration: 0.4, extraBounce: 0)
            )
        }
    }

    @Animatable
    fileprivate struct AlertFrame {
        var opacity: CGFloat = 0
        var scale: CGFloat = 1.1
        var tapOpacity: CGFloat = 0
        var tapScale: CGFloat = 1
    }
}

private extension View {
    @ViewBuilder
    func optionalLiquidGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.clear, in: .rect(cornerRadius: 30))
        } else {
            self
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.background)
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(.gray.opacity(0.4), lineWidth: 1)
                    }
                }
        }
    }
}

#Preview {
    AlarmPermission(
        title: "Stay on track",
        description: "Enable notifications for alarm reminders, Morning Lock updates, and important alerts.",
        primaryActionTitle: "Enable Notifications",
        secondaryActionTitle: "Now Now",
        primaryAction: {
            print("Enable selected")
        },
        secondaryAction: {
            print("Ask Later selected")
        }
    )
}


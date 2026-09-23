//
//  AlarmPermission.swift
//  Loop
//

import SwiftUI

struct AlarmPermission: View {
    var tint: Color = .orange
    var title: String
    var description: String
    var primaryActionTitle: String
    var secondaryActionTitle: String
    var isPrimaryActionEnabled: Bool = true
    var primaryAction: () -> Void
    var secondaryAction: () -> Void

    var body: some View {
        PermissionScreen(
            tint: tint,
            title: title,
            description: description,
            showsNotch: false,
            primaryActionTitle: primaryActionTitle,
            secondaryActionTitle: secondaryActionTitle,
            isPrimaryActionEnabled: isPrimaryActionEnabled,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction
        ) {
            AlarmIslandAnimation(tint: tint)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .top
                )
        }
    }
}

private struct AlarmIslandAnimation: View {
    var tint: Color

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    private struct AlertFrame {
        var width: CGFloat = 120
        var height: CGFloat = 37
        var contentOpacity: CGFloat = 0
        var contentOffset: CGFloat = 6
        var iconRotation: CGFloat = 0
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = min(
                1,
                max(0, geometry.size.width - 12) / 350
            )

            Group {
                if reduceMotion {
                    island(
                        AlertFrame(
                            width: 350,
                            height: 84,
                            contentOpacity: 1,
                            contentOffset: 0
                        )
                    )
                    .offset(y: -12)
                } else {
                    animatedIsland
                }
            }
            .frame(
                width: 350,
                height: 100,
                alignment: .top
            )
            .scaleEffect(scale, anchor: .top)
            .frame(
                width: geometry.size.width,
                height: 100 * scale,
                alignment: .top
            )
        }
        .padding(.top, 20)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var animatedIsland: some View {
        KeyframeAnimator(
            initialValue: AlertFrame(),
            repeating: true
        ) { frame in
            let expansion = min(
                1,
                max(0, (frame.height - 37) / (84 - 37))
            )

            island(frame)
                .offset(y: -12 * expansion)
        } keyframes: { _ in
            // Compact → expanded → hold → compact.
            KeyframeTrack(\.width) {
                LinearKeyframe(120, duration: 0.8)

                SpringKeyframe(
                    350,
                    duration: 0.6,
                    spring: .smooth(
                        duration: 0.5,
                        extraBounce: 0.08
                    )
                )

                LinearKeyframe(350, duration: 2.1)

                SpringKeyframe(
                    120,
                    duration: 0.55,
                    spring: .smooth(duration: 0.45)
                )

                LinearKeyframe(120, duration: 0.35)
            }

            KeyframeTrack(\.height) {
                LinearKeyframe(37, duration: 0.8)

                SpringKeyframe(
                    84,
                    duration: 0.6,
                    spring: .smooth(
                        duration: 0.5,
                        extraBounce: 0.08
                    )
                )

                LinearKeyframe(84, duration: 2.1)

                SpringKeyframe(
                    37,
                    duration: 0.55,
                    spring: .smooth(duration: 0.45)
                )

                LinearKeyframe(37, duration: 0.35)
            }

            // Reveal the contents after expansion begins.
            KeyframeTrack(\.contentOpacity) {
                LinearKeyframe(0, duration: 1.0)
                LinearKeyframe(1, duration: 0.22)
                LinearKeyframe(1, duration: 2.08)
                LinearKeyframe(0, duration: 0.16)
                LinearKeyframe(0, duration: 0.94)
            }

            KeyframeTrack(\.contentOffset) {
                LinearKeyframe(6, duration: 1.0)

                SpringKeyframe(
                    0,
                    duration: 0.35,
                    spring: .smooth(duration: 0.3)
                )

                LinearKeyframe(0, duration: 1.95)
                LinearKeyframe(6, duration: 0.2)
                LinearKeyframe(6, duration: 0.9)
            }

            // Ring the icon without shaking the banner.
            KeyframeTrack(\.iconRotation) {
                LinearKeyframe(0, duration: 1.35)

                LinearKeyframe(-12, duration: 0.07)
                LinearKeyframe(12, duration: 0.09)
                LinearKeyframe(-9, duration: 0.09)
                LinearKeyframe(9, duration: 0.09)
                LinearKeyframe(0, duration: 0.10)

                LinearKeyframe(0, duration: 0.65)

                LinearKeyframe(-12, duration: 0.07)
                LinearKeyframe(12, duration: 0.09)
                LinearKeyframe(-9, duration: 0.09)
                LinearKeyframe(9, duration: 0.09)
                LinearKeyframe(0, duration: 0.10)

                LinearKeyframe(0, duration: 1.52)
            }
        }
    }

    private func island(_ frame: AlertFrame) -> some View {
        RoundedRectangle(
            cornerRadius: frame.height / 2,
            style: .continuous
        )
        .fill(.black)
        .overlay {
            HStack(spacing: 14) {
                Image(systemName: "alarm.fill")
                    .font(
                        .system(size: 40, weight: .semibold)
                    )
                    .foregroundStyle(tint)
                    .rotationEffect(
                        .degrees(Double(frame.iconRotation))
                    )
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 0) {
                    Text("loop")
                        .font(
                            .system(size: 14, weight: .semibold)
                        )
                        .foregroundStyle(tint.opacity(0.6))

                    Text("Alarm")
                        .font(
                            .system(size: 20, weight: .semibold)
                        )
                        .foregroundStyle(tint)
                }

                Spacer(minLength: 0)

                Image(systemName: "xmark")
                    .font(
                        .system(size: 23, weight: .semibold)
                    )
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        Color(white: 0.19),
                        in: Circle()
                    )
            }
            .padding(.horizontal, 22)
            .frame(width: 350, height: 84)
            .offset(y: frame.contentOffset)
            .opacity(Double(frame.contentOpacity))
        }
        .frame(
            width: frame.width,
            height: frame.height
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: frame.height / 2,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: frame.height / 2,
                style: .continuous
            )
            .strokeBorder(
                .white.opacity(0.10),
                lineWidth: 1
            )
        }
    }
}

#Preview {
    AlarmPermission(
        title: "Never sleep through an alarm with Loop",
        description: "Allow Loop to schedule alarms and wake you at the time you choose.",
        primaryActionTitle: "Allow Alarms",
        secondaryActionTitle: "Not Now",
        primaryAction: {
            print("Enable selected")
        },
        secondaryAction: {
            print("Ask Later selected")
        }
    )
}

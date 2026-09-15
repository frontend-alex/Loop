//
//  EnableAlarm.swift
//  Loop
//
//  Created by Aleksander Ivanov on 14/09/2026.
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

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if !accessibilityReduceMotion && !dynamicTypeSize.isAccessibilitySize {
                    permissionAnimation()
                        .frame(maxWidth: 220)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.md)
                        .padding(.bottom, DesignSystem.Spacing.lg)
                        .accessibilityHidden(true)
                }

                permissionContent()
            }
        }
    }

    // MARK: - Permission content

    @ViewBuilder
    private func permissionContent() -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            AppButton(
                action: primaryAction
            ){
                Text(primaryActionTitle)
            }

            .disabled(!isPrimaryActionEnabled)

            AppButton(
                variant: .ghost,
                action: secondaryAction
            ){
                Text(secondaryActionTitle)
            }
        }
        .background(Color.clear)
    }

    // MARK: - Alarm phone animation

    @ViewBuilder
    private func permissionAnimation() -> some View {
        let phoneRatio: CGFloat = 390 / 870
        let phoneCornerRadius: CGFloat = 70

        GeometryReader { geometry in
            let size = geometry.size
            let scale = min(
                size.width / 390,
                size.height / 870
            )

            Color.clear
                .keyframeAnimator(
                    initialValue: AlarmAnimationValues(),
                    repeating: true
                ) { _, value in
                    ZStack {
                        // Screen-off state
                        RoundedRectangle(
                            cornerRadius: phoneCornerRadius * scale,
                            style: .continuous
                        )
                        .fill(.black)

                        // Screen glow
                        RoundedRectangle(
                            cornerRadius: phoneCornerRadius * scale,
                            style: .continuous
                        )
                        .fill(tint)
                        .blur(radius: 28)
                        .opacity(value.glowOpacity)
                        .scaleEffect(0.96)

                        // Actual alarm screen
                        AlarmMockScreen(
                            time: "7:33",
                            alarmName: "Alarm",
                            tint: tint
                        )
                        .opacity(value.screenOpacity)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: phoneCornerRadius * scale,
                                style: .continuous
                            )
                        )

                        // Mock phone border
                        RoundedRectangle(
                            cornerRadius: phoneCornerRadius * scale,
                            style: .continuous
                        )
                        .stroke(
                            .primary,
                            lineWidth: max(1, 2 * scale)
                        )

                        // Dynamic Island
                        VStack {
                            Capsule()
                                .fill(.black)
                                .overlay {
                                    Capsule()
                                        .stroke(
                                            Color.primary.opacity(0.1),
                                            lineWidth: 1
                                        )
                                }
                                .frame(
                                    width: 120 * scale,
                                    height: 36 * scale
                                )
                                .padding(.top, 11 * scale)

                            Spacer()
                        }
                        .opacity(value.screenOpacity)
                    }
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: phoneCornerRadius * scale,
                            style: .continuous
                        )
                    )
                    .rotationEffect(.degrees(value.rotation))
                    .offset(
                        x: value.horizontalOffset,
                        y: value.verticalOffset
                    )
                    .scaleEffect(value.scale)
                } keyframes: { _ in
                    // Screen:
                    // off → fade in → stay on → fade out → pause
                    KeyframeTrack(\.screenOpacity) {
                        LinearKeyframe(0, duration: 0.50)
                        CubicKeyframe(1, duration: 0.30)
                        LinearKeyframe(1, duration: 0.60)
                        LinearKeyframe(1, duration: 0.28)
                        CubicKeyframe(0, duration: 0.35)
                        LinearKeyframe(0, duration: 0.85)
                    }

                    KeyframeTrack(\.glowOpacity) {
                        LinearKeyframe(0, duration: 0.50)
                        CubicKeyframe(0.25, duration: 0.30)
                        LinearKeyframe(0.25, duration: 0.60)
                        LinearKeyframe(0.25, duration: 0.28)
                        CubicKeyframe(0, duration: 0.35)
                        LinearKeyframe(0, duration: 0.85)
                    }

                    // Shake begins after the screen has faded in
                    KeyframeTrack(\.rotation) {
                        LinearKeyframe(0, duration: 0.80)

                        LinearKeyframe(-1.5, duration: 0.07)
                        LinearKeyframe(1.5, duration: 0.07)
                        LinearKeyframe(-1.2, duration: 0.07)
                        LinearKeyframe(1.2, duration: 0.07)
                        LinearKeyframe(-0.6, duration: 0.07)
                        LinearKeyframe(0.6, duration: 0.07)

                        LinearKeyframe(-0.9, duration: 0.07)
                        LinearKeyframe(0.9, duration: 0.07)
                        LinearKeyframe(-0.7, duration: 0.07)
                        LinearKeyframe(0.7, duration: 0.07)

                        SpringKeyframe(0, duration: 0.18)
                        LinearKeyframe(0, duration: 1.20)
                    }

                    KeyframeTrack(\.horizontalOffset) {
                        LinearKeyframe(0, duration: 0.80)

                        LinearKeyframe(-5, duration: 0.07)
                        LinearKeyframe(5, duration: 0.07)
                        LinearKeyframe(-4, duration: 0.07)
                        LinearKeyframe(4, duration: 0.07)
                        LinearKeyframe(-2, duration: 0.07)
                        LinearKeyframe(2, duration: 0.07)

                        LinearKeyframe(-3, duration: 0.07)
                        LinearKeyframe(3, duration: 0.07)
                        LinearKeyframe(-2, duration: 0.07)
                        LinearKeyframe(2, duration: 0.07)

                        SpringKeyframe(0, duration: 0.18)
                        LinearKeyframe(0, duration: 1.20)
                    }

                    KeyframeTrack(\.verticalOffset) {
                        LinearKeyframe(0, duration: 0.80)
                        LinearKeyframe(-2, duration: 0.14)
                        LinearKeyframe(2, duration: 0.14)
                        LinearKeyframe(-2, duration: 0.07)
                        LinearKeyframe(2, duration: 0.07)
                        LinearKeyframe(-1, duration: 0.07)
                        LinearKeyframe(1, duration: 0.07)
                        SpringKeyframe(0, duration: 0.25)
                        LinearKeyframe(0, duration: 1.27)
                    }

                    KeyframeTrack(\.scale) {
                        LinearKeyframe(1, duration: 0.50)
                        CubicKeyframe(1.01, duration: 0.30)
                        LinearKeyframe(1.01, duration: 0.60)
                        LinearKeyframe(1.01, duration: 0.28)
                        CubicKeyframe(1, duration: 0.35)
                        LinearKeyframe(1, duration: 0.85)
                    }
                }
        }
        .aspectRatio(phoneRatio, contentMode: .fit)
    }
}

// MARK: - Alarm screen inside mock phone

private struct AlarmMockScreen: View {
    var time: String
    var alarmName: String
    var tint: Color

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 390

            ZStack {
                Color(uiColor: .systemBackground)

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 118 * scale)

                    alarmHeader(scale: scale)

                    Text(time)
                        .font(
                            .system(
                                size: 108 * scale,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .padding(.top, 6 * scale)

                    Spacer()

                    snoozeButton(scale: scale)

                    slideToStop(scale: scale)
                        .padding(.top, 24 * scale)
                        .padding(.bottom, 58 * scale)
                }
            }
        }
    }

    // MARK: Alarm title

    private func alarmHeader(scale: CGFloat) -> some View {
        HStack(spacing: 10 * scale) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 24 * scale))
                .foregroundStyle(.secondary)

            Text(alarmName)
                .font(
                    .system(
                        size: 24 * scale,
                        weight: .medium,
                        design: .rounded
                    )
                )
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Snooze button

    private func snoozeButton(scale: CGFloat) -> some View {
        Button(action: {}) {
            Text("Snooze")
                .font(
                    .system(
                        size: 25 * scale,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 96 * scale)
                .background(tint)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 30 * scale)
    }

    // MARK: Slide to stop

    private func slideToStop(scale: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.primary.opacity(0.10))
                .frame(height: 96 * scale)

            Text("slide to stop")
                .font(
                    .system(
                        size: 23 * scale,
                        weight: .regular,
                        design: .rounded
                    )
                )
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.leading, 55 * scale)

            Circle()
                .fill(Color(uiColor: .systemBackground))
                .overlay {
                    Circle()
                        .stroke(Color.primary.opacity(0.14), lineWidth: max(1, scale))
                }
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 5 * scale,
                        style: .continuous
                    )
                        .fill(.primary)
                        .frame(
                            width: 31 * scale,
                        height: 31 * scale
                    )
                }
                .frame(
                    width: 88 * scale,
                    height: 88 * scale
                )
                .padding(.leading, 4 * scale)
        }
        .padding(.horizontal, 30 * scale)
    }
}

// MARK: - Animation values

private struct AlarmAnimationValues {
    var screenOpacity: CGFloat = 0
    var glowOpacity: CGFloat = 0

    var rotation: CGFloat = 0
    var horizontalOffset: CGFloat = 0
    var verticalOffset: CGFloat = 0
    var scale: CGFloat = 1
}

// MARK: - Preview

#Preview {
    AlarmPermission(
        title: "Never sleep through an alarm",
        description: "Loop needs alarm access to begin your Morning Lock session.",
        primaryActionTitle: "Enable Alarm Access",
        secondaryActionTitle: "Ask Later",
        primaryAction: {
            print("Enable selected")
        },
        secondaryAction: {
            print("Ask Later selected")
        }
    )
}

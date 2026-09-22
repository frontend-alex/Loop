//
//  PermissionScreen.swift
//  loop
//
//  Created by Aleksander Ivanov on 16/09/2026.
//

import SwiftUI

struct PermissionScreen<PhoneContent: View>: View {
    let tint: Color
    let title: String
    let description: String
    let showsNotch: Bool
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let isPrimaryActionEnabled: Bool
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    let phoneContent: () -> PhoneContent

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    init(
        tint: Color = .orange,
        title: String,
        description: String,
        showsNotch: Bool = true,
        primaryActionTitle: String,
        secondaryActionTitle: String,
        isPrimaryActionEnabled: Bool = true,
        primaryAction: @escaping () -> Void,
        secondaryAction: @escaping () -> Void,
        @ViewBuilder phoneContent: @escaping () -> PhoneContent
    ) {
        self.tint = tint
        self.title = title
        self.description = description
        self.showsNotch = showsNotch
        self.primaryActionTitle = primaryActionTitle
        self.secondaryActionTitle = secondaryActionTitle
        self.isPrimaryActionEnabled = isPrimaryActionEnabled
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.phoneContent = phoneContent
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if !accessibilityReduceMotion && !dynamicTypeSize.isAccessibilitySize {
                     IphoneScreen(tint: tint, showsNotch: showsNotch) {
                        phoneContent()
                    }
                    .frame(maxWidth: 200)
                    .accessibilityHidden(true)
                }

                permissionContent()
            }
        }
    }

    private func permissionContent() -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            AppButton(action: primaryAction) {
                Text(primaryActionTitle)
            }
            .disabled(!isPrimaryActionEnabled)
            
            AppButton(variant: .ghost, action: secondaryAction) {
                Text(secondaryActionTitle)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(background)
                .blur(radius: 25)
                .padding(-80)
                .ignoresSafeArea()
        }
    }

    private var background: Color {
        colorScheme == .dark ? .black : .white
    }
}

#Preview("Permission Screen") {
    PermissionScreen(
        tint: .orange,
        title: "Stay focused with Loop Alarm",
        description: "Allow access to keep your focus sessions running smoothly.",
        primaryActionTitle: "Continue",
        secondaryActionTitle: "Ask Later",
        primaryAction: {},
        secondaryAction: {}
    ) {
        VStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.2))
                .frame(width: 150, height: 22)

            RoundedRectangle(cornerRadius: 6)
                .fill(.white.opacity(0.2))
                .frame(height: 18)

            RoundedRectangle(cornerRadius: 6)
                .fill(.white.opacity(0.2))
                .frame(height: 18)
                .padding(.trailing, 60)
        }
        .frame(width: 280)
        .padding(20)
        .background(.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 30))
    }
}

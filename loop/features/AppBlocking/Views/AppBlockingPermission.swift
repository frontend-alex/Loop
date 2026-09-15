//
//  AppBlockingPermission.swift
//  loop
//
//  Created by Aleksander Ivanov on 14/09/2026.
//

import SwiftUI

struct AppBlockingPermission: View {
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
    @State private var lockedIcons: Set<String> = []

    private struct MockApp: Identifiable {
        let id: String
        let icon: String
        let color: Color
        let isLockable: Bool
    }

    private let mockApps = [
        MockApp(id: "game", icon: "gamecontroller.fill", color: .red, isLockable: true),
        MockApp(id: "video", icon: "play.rectangle.fill", color: .orange, isLockable: true),
        MockApp(id: "social", icon: "music.note", color: .pink, isLockable: true),
        MockApp(id: "book", icon: "book.fill", color: .blue, isLockable: false),
        MockApp(id: "music", icon: "headphones", color: .teal, isLockable: false),
        MockApp(id: "reading", icon: "leaf.fill", color: .green, isLockable: false)
    ]

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
                        .task {
                            await animateAppLocks()
                        }
                }

                permissionContent()
            }
        }
    }

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
                action: primaryAction,
            ){
                Text(primaryActionTitle)
            }
            .disabled(!isPrimaryActionEnabled)
            .padding(.top, DesignSystem.Spacing.md)

            
            AppButton(
                variant: .ghost,
                action: secondaryAction,
            ){
                Text(secondaryActionTitle)
            }
        }
    }

    private func permissionAnimation() -> some View {
        let phoneRatio: CGFloat = 390 / 870
        let phoneCornerRadius: CGFloat = 70

        return GeometryReader { geometry in
            let size = geometry.size
            let scale = min(size.width / 390, size.height / 870)

            ZStack {
                RoundedRectangle(cornerRadius: phoneCornerRadius * scale)
                    .fill(Color(uiColor: .systemBackground))

                VStack(spacing: 0) {

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 3),
                        spacing: 20 * scale
                    ) {
                        ForEach(mockApps) { app in
                            let isLocked = lockedIcons.contains(app.id)

                            ZStack {
                                Image(systemName: app.icon)
                                    .opacity(isLocked ? 0 : 1)

                                Image(systemName: "lock.fill")
                                    .opacity(isLocked ? 1 : 0)
                            }
                            .font(.system(size: 32 * scale, weight: .semibold))
                            .foregroundStyle(.white.opacity(isLocked ? 0.5 : 1))
                            .frame(width: 78 * scale, height: 78 * scale)
                            .background(
                                app.color.opacity(isLocked ? 0.18 : 0.85),
                                in: RoundedRectangle(cornerRadius: 20 * scale)
                            )
                            .scaleEffect(isLocked ? 1.08 : 1)
                            .animation(.easeInOut(duration: 0.9), value: isLocked)
                        }
                    }
                    .padding(.horizontal, 30 * scale)
                    .padding(.top, 100 * scale)

                    Spacer()
                }

                dynamicIsland(scale: scale)
            }
            .clipShape(RoundedRectangle(cornerRadius: phoneCornerRadius * scale))
            .overlay {
                RoundedRectangle(cornerRadius: phoneCornerRadius * scale)
                    .stroke(.primary, lineWidth: max(1, 2 * scale))
            }
        }
        .aspectRatio(phoneRatio, contentMode: .fit)
    }

    private func animateAppLocks() async {
        while !Task.isCancelled {
            for app in mockApps.filter(\.isLockable).shuffled() {
                guard !Task.isCancelled else { return }

                let delay = UInt64.random(in: 450_000_000...950_000_000)
                try? await Task.sleep(nanoseconds: delay)

                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: 0.9)) {
                    lockedIcons.insert(app.id)
                }
            }

            try? await Task.sleep(nanoseconds: 1_400_000_000)

            guard !Task.isCancelled else { return }

            for app in mockApps.filter(\.isLockable).shuffled() {
                guard !Task.isCancelled else { return }

                let delay = UInt64.random(in: 450_000_000...950_000_000)
                try? await Task.sleep(nanoseconds: delay)

                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: 0.9)) {
                    lockedIcons.remove(app.id)
                }
            }

            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    private func dynamicIsland(scale: CGFloat) -> some View {
        VStack {
            Capsule()
                .fill(.black)
                .frame(width: 120 * scale, height: 36 * scale)
                .padding(.top, 11 * scale)

            Spacer()
        }
    }
}

#Preview {
    AppBlockingPermission(
        title: "Protect your focus",
        description: "Loop needs permission to restrict distracting apps during a focus session.",
        primaryActionTitle: "Enable App Blocking",
        secondaryActionTitle: "Skip for Now",
        primaryAction: {},
        secondaryAction: {}
    )
}

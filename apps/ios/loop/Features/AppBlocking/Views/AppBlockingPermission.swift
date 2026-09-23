//
//  AppBlockingPermission.swift
//  loop
//
//  Created by Aleksander Ivanov on 14/09/2026.
//

import SwiftUI

struct AppBlockingPermission: View {
    var title: String
    var description: String

    var primaryActionTitle: String
    var secondaryActionTitle: String
    var isPrimaryActionEnabled: Bool = true

    var primaryAction: () -> Void
    var secondaryAction: () -> Void

    @State private var lockPhases: [String: LockPhase] = [:]

    private struct MockApp: Identifiable {
        let id: String
    }

    private let mockApps = [
        MockApp(id: "one"),
        MockApp(id: "two"),
        MockApp(id: "three"),
        MockApp(id: "four"),
        MockApp(id: "five"),
        MockApp(id: "six")
    ]

    var body: some View {
        PermissionScreen(
            tint: .orange,
            title: title,
            description: description,
            primaryActionTitle: primaryActionTitle,
            secondaryActionTitle: secondaryActionTitle,
            isPrimaryActionEnabled: isPrimaryActionEnabled,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction
        ) {
            permissionAnimation()
                .task {
                    await animateAppLocks()
                }
        }
    }


    private func permissionAnimation() -> some View {
        VStack(spacing: 0) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 3),
                spacing: 20
            ) {
                ForEach(mockApps) { app in
                    let phase = lockPhases[app.id] ?? .idle

                    ZStack {
                        if phase != .idle {
                            Image(systemName: phase == .unlocking ? "lock.open.fill" : "lock.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                    }
                    .frame(width: 78, height: 78)
                    .background(
                        .gray.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                    .scaleEffect(
                        phase == .clicking ? 0.82 : phase == .unlocking ? 0.68 : phase == .locked ? 1.08 : 1
                    )
                    .rotationEffect(.degrees(phase == .clicking ? -8 : phase == .unlocking ? 8 : 0))
                    .animation(.spring(response: 0.22, dampingFraction: 0.55), value: phase)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 100)

            Spacer()
        }
    }

    private func animateAppLocks() async {
        while !Task.isCancelled {
            for app in mockApps.shuffled() {
                guard !Task.isCancelled else { return }

                let delay = UInt64.random(in: 450_000_000...950_000_000)
                try? await Task.sleep(nanoseconds: delay)

                guard !Task.isCancelled else { return }

                withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) {
                    lockPhases[app.id] = .clicking
                }

                try? await Task.sleep(nanoseconds: 220_000_000)

                guard !Task.isCancelled else { return }

                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    lockPhases[app.id] = .locked
                }
            }

            try? await Task.sleep(nanoseconds: 1_400_000_000)

            guard !Task.isCancelled else { return }

            for app in mockApps.shuffled() {
                guard !Task.isCancelled else { return }

                let delay = UInt64.random(in: 450_000_000...950_000_000)
                try? await Task.sleep(nanoseconds: delay)

                guard !Task.isCancelled else { return }

                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    lockPhases[app.id] = .unlocking
                }

                try? await Task.sleep(nanoseconds: 300_000_000)

                guard !Task.isCancelled else { return }

                withAnimation(.easeOut(duration: 0.25)) {
                    lockPhases[app.id] = .idle
                }
            }

            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    private enum LockPhase: Equatable {
        case idle
        case clicking
        case locked
        case unlocking
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

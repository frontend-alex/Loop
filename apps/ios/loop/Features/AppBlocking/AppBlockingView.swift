import ComposableArchitecture
import FamilyControls
import SwiftUI

struct AppBlockingView: View {
    @Bindable var store: StoreOf<AppBlockingFeature>

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: Spacing.md) {
            if store.authorizationStatus == .authorized {
                FamilyActivityPicker(selection: $store.selection.sending(\.selectionChanged))
                    .scrollContentBackground(.hidden)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask {
                        if reduceTransparency {
                            Rectangle()
                        } else {
                            // Fade the top edge only; the bottom holds the picker's search field.
                            LinearGradient(
                                stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    }
                    .background(.backgroundPrimary)
                    .padding(.horizontal, -Spacing.lg)
                    .ignoresSafeArea(.container, edges: .bottom)
            } else {
                Spacer()
                PermissionScreen(
                    title: "Protect your focus",
                    description: "Loop needs permission to restrict distracting apps during a focus session.",
                    primaryTitle: "Enable App Blocking",
                    secondaryTitle: "Skip for Now",
                    isPrimaryEnabled: store.authorizationStatus != .requesting,
                    primaryAction: { store.send(.authorizationRequested) },
                    secondaryAction: { store.send(.permissionSkipped) }
                ) {
                    LockingAppsAnimation()
                }
            }

            if let message = store.errorMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.danger)
                    .multilineTextAlignment(.center)
            }
        }
        .task { store.send(.task) }
    }
}

/// A grid of placeholder apps that lock and unlock at random.
private struct LockingAppsAnimation: View {
    private enum Phase {
        case idle, clicking, locked, unlocking

        var scale: CGFloat {
            switch self {
            case .clicking: 0.82
            case .unlocking: 0.68
            case .locked: 1.08
            case .idle: 1
            }
        }
    }

    @State private var phases = Array(repeating: Phase.idle, count: 6)

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
            ForEach(phases.indices, id: \.self) { index in
                let phase = phases[index]
                ZStack {
                    if phase != .idle {
                        Image(systemName: phase == .unlocking ? "lock.open.fill" : "lock.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                }
                .frame(width: 78, height: 78)
                .background(.gray.opacity(0.15), in: .rect(cornerRadius: 20))
                .scaleEffect(phase.scale)
                .rotationEffect(.degrees(phase == .clicking ? -8 : phase == .unlocking ? 8 : 0))
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 100)
        .frame(maxHeight: .infinity, alignment: .top)
        .task { await animate() }
    }

    private func animate() async {
        do {
            while true {
                for index in phases.indices.shuffled() {
                    try await step(index, .clicking, after: .random(in: 0.45...0.95), animation: .spring(response: 0.22, dampingFraction: 0.55))
                    try await step(index, .locked, after: 0.22, animation: .spring(response: 0.35, dampingFraction: 0.65))
                }
                try await Task.sleep(for: .seconds(1.4))
                for index in phases.indices.shuffled() {
                    try await step(index, .unlocking, after: .random(in: 0.45...0.95), animation: .spring(response: 0.25, dampingFraction: 0.6))
                    try await step(index, .idle, after: 0.3, animation: .easeOut(duration: 0.25))
                }
                try await Task.sleep(for: .seconds(1))
            }
        } catch {
            // Cancelled when the view disappears.
        }
    }

    private func step(_ index: Int, _ phase: Phase, after seconds: Double, animation: Animation) async throws {
        try await Task.sleep(for: .seconds(seconds))
        withAnimation(animation) { phases[index] = phase }
    }
}

#Preview {
    AppBlockingView(store: Store(initialState: AppBlockingFeature.State()) { AppBlockingFeature() })
}

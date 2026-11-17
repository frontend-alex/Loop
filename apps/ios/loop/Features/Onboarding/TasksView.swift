import ComposableArchitecture
import SwiftUI

/// Picks the Wake-up Tasks the alarm can ask for; one is given each morning.
struct TasksView: View {
    let store: StoreOf<OnboardingFeature>
    /// Set while the list scrolls, so the host can tuck the arrow away.
    @Binding var isScrolling: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                ForEach(WakeUpTask.all) { task in
                    OptionButton(isSelected: store.selectedTaskIDs.contains(task.id)) {
                        store.send(.taskToggled(task.id))
                    } label: {
                        Image(task.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.title3.weight(.medium))
                            Text(task.detail)
                                .font(.subheadline)
                                .opacity(0.7)
                        }
                        // One line each; shrink rather than wrap on zoomed screens or large text.
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    }
                }
            }
        }
        // Scrolls under the floating arrow; the bar's safe-area inset lets the last row clear it.
        .contentMargins(.top, Spacing.xs, for: .scrollContent)
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .onScrollPhaseChange { _, phase in isScrolling = phase.isScrolling }
        .mask {
            // Fade rows out under the heading instead of cutting them off.
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: Spacing.lg)
                Color.black
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .sensoryFeedback(.selection, trigger: store.selectedTaskIDs)
    }
}

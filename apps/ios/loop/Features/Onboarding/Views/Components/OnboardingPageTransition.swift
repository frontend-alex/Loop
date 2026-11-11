import ComposableArchitecture
import SwiftUI

struct OnboardingPageTransition: Transition {
    let store: StoreOf<OnboardingProvider>
    let page: Int
    let reduceMotion: Bool

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .offset(x: horizontalOffset(for: phase))
            .opacity(phase.isIdentity ? 1 : 0)
    }

    func horizontalOffset(for phase: TransitionPhase) -> CGFloat {
        guard !phase.isIdentity, !reduceMotion else { return 0 }
        // The removed page keeps its own index, but reads the new destination.
        // This avoids reusing its old forward direction when navigating back.
        let movesRight = phase == .willAppear
            ? !store.isNavigatingBack
            : store.currentStep < page
        return DesignSystem.Spacing.lg * (movesRight ? 1 : -1)
    }
}

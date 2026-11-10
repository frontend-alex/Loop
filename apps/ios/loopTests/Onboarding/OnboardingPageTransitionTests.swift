import ComposableArchitecture
import SwiftUI
import Testing
@testable import loop

@MainActor
struct OnboardingPageTransitionTests {
    @Test(arguments: [true, false])
    func enteringAndLeavingPagesFollowTheSameNavigationDirection(backwards: Bool) {
        let store = Store(initialState: OnboardingProvider.State(
            questionIndex: backwards ? 1 : 2,
            isNavigatingBack: backwards
        )) {
            EmptyReducer<OnboardingProvider.State, OnboardingProvider.Action>()
        }
        let entering = OnboardingPageTransition(
            store: store, page: store.currentStep, reduceMotion: false
        )
        let leaving = OnboardingPageTransition(
            store: store, page: backwards ? 2 : 1, reduceMotion: false
        )

        let distance = DesignSystem.Spacing.lg
        #expect(entering.horizontalOffset(for: .willAppear) == (backwards ? -distance : distance))
        #expect(leaving.horizontalOffset(for: .didDisappear) == (backwards ? distance : -distance))
        #expect(entering.horizontalOffset(for: .identity) == 0)
    }

    @Test func reduceMotionNeverSlidesPages() {
        let store = Store(initialState: OnboardingProvider.State(questionIndex: 1)) {
            EmptyReducer<OnboardingProvider.State, OnboardingProvider.Action>()
        }
        let transition = OnboardingPageTransition(store: store, page: 0, reduceMotion: true)

        #expect(transition.horizontalOffset(for: .willAppear) == 0)
        #expect(transition.horizontalOffset(for: .identity) == 0)
        #expect(transition.horizontalOffset(for: .didDisappear) == 0)
    }
}

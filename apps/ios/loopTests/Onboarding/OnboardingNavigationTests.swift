import ComposableArchitecture
import Foundation
import Testing
@testable import loop

@MainActor
struct OnboardingNavigationTests {
    private let defaults: UserDefaults
    private let fixture: (session: URLSession, baseURL: URL)

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "loop.navigation.tests.\(UUID())"))
        fixture = try OnboardingURLProtocol.fixture()
    }

    @Test func backThenContinueReversesTheTransitionDirection() async {
        let store = TestStore(initialState: OnboardingProvider.State(questionIndex: 1)) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "test-token" }
        }

        await store.send(.backTapped) {
            $0.questionIndex = 0
            $0.isNavigatingBack = true
        }
        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.isNavigatingBack = false
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }
    }

    @Test func backAtTheFirstQuestionDoesNotChangeTheDirection() async {
        let store = TestStore(initialState: OnboardingProvider.State()) {
            OnboardingProvider(defaults: defaults)
        }

        await store.send(.backTapped)
    }

    @Test(arguments: [
        OnboardingProvider.Action.alarm(.delegate(.saved)),
        .alarm(.delegate(.skipped)),
        .appBlocking(.delegate(.skipped))
    ])
    func featureCompletionAlwaysMovesForward(action: OnboardingProvider.Action) async {
        let isAppBlocking: Bool
        if case .appBlocking = action { isAppBlocking = true } else { isAppBlocking = false }
        let store = TestStore(initialState: OnboardingProvider.State(
            step: isAppBlocking ? .apps : .alarm,
            isNavigatingBack: true
        )) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "test-token" }
        }

        await store.send(action) {
            $0.step = isAppBlocking ? .tasks : .apps
            $0.isNavigatingBack = false
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }
    }
}

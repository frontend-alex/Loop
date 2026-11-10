import ComposableArchitecture
import Foundation
import Testing
@testable import loop

@MainActor
struct AlarmSetupTests {
    private let initialTime = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func initializingTheClockKeepsSkipAvailable() async {
        let store = TestStore(initialState: AlarmProvider.State()) {
            AlarmProvider()
        } withDependencies: {
            $0.date.now = initialTime
        }

        await store.send(.appeared) {
            $0.alarm.time = initialTime
            $0.hasInitializedTime = true
        }
        #expect(store.state.canSkipSetup)
    }

    @Test(arguments: [60.0, 3_600.0])
    func changingEitherWheelRemovesSkip(offset: TimeInterval) async {
        var state = AlarmProvider.State(hasInitializedTime: true)
        state.alarm.time = initialTime
        let store = TestStore(initialState: state) {
            AlarmProvider()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
        }
        let newTime = initialTime.addingTimeInterval(offset)

        await store.send(.timeChanged(newTime)) {
            $0.alarm.time = newTime
            $0.hasEditedTime = true
        }
        #expect(store.state.canSkipSetup == false)

        await store.send(.timeChanged(initialTime)) {
            $0.alarm.time = initialTime
        }
        #expect(store.state.canSkipSetup == false)
        await store.send(.skipTapped)
    }

    @Test func returningToTheAlarmRestoresSkipWithoutResettingTheTime() async {
        var state = AlarmProvider.State(
            hasInitializedTime: true, authorizationStatus: .authorized
        )
        state.alarm.time = initialTime
        let store = TestStore(initialState: state) {
            AlarmProvider()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
        }
        let selectedTime = initialTime.addingTimeInterval(60)

        await store.send(.timeChanged(selectedTime)) {
            $0.alarm.time = selectedTime
            $0.hasEditedTime = true
        }
        await store.send(.appeared) {
            $0.hasEditedTime = false
        }
        #expect(store.state.canSkipSetup)
        #expect(store.state.alarm.time == selectedTime)

        await store.send(.timeChanged(initialTime)) {
            $0.alarm.time = initialTime
            $0.hasEditedTime = true
        }
        #expect(store.state.canSkipSetup == false)
    }

    @Test func normalizingSecondsDoesNotCountAsEditingAWheel() async {
        var state = AlarmProvider.State(hasInitializedTime: true)
        state.alarm.time = initialTime.addingTimeInterval(30)
        let store = TestStore(initialState: state) {
            AlarmProvider()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
        }

        await store.send(.timeChanged(initialTime)) {
            $0.alarm.time = initialTime
        }
        #expect(store.state.canSkipSetup)
    }

    @Test(arguments: [
        AlarmProvider.AuthorizationStatus.unknown, .denied, .authorized
    ])
    func untouchedAlarmCanBeSkippedWithoutScheduling(
        status: AlarmProvider.AuthorizationStatus
    ) async {
        let store = TestStore(initialState: AlarmProvider.State(authorizationStatus: status)) {
            AlarmProvider()
        }

        await store.send(.skipTapped)
        await store.receive(.delegate(.skipped))
        #expect(store.state.alarm.scheduledID == nil)
        #expect(store.state.isSaving == false)
    }

    @Test func editedAlarmCannotBeSkipped() async {
        let store = TestStore(initialState: AlarmProvider.State(
            hasEditedTime: true, authorizationStatus: .authorized
        )) {
            AlarmProvider()
        }

        await store.send(.skipTapped)
    }

    @Test func previouslyScheduledAlarmDoesNotHideSkipBeforeAWheelEdit() async {
        let scheduledID = UUID()
        var state = AlarmProvider.State(
            hasInitializedTime: true, authorizationStatus: .authorized
        )
        state.alarm.time = initialTime
        state.alarm.scheduledID = scheduledID
        let store = TestStore(initialState: state) {
            AlarmProvider()
        } withDependencies: {
            $0.calendar = Calendar(identifier: .gregorian)
        }

        #expect(store.state.canSkipSetup)
        await store.send(.skipTapped)
        await store.receive(.delegate(.skipped))
        #expect(store.state.alarm.scheduledID == scheduledID)

        let newTime = initialTime.addingTimeInterval(60)
        await store.send(.timeChanged(newTime)) {
            $0.alarm.time = newTime
            $0.hasEditedTime = true
        }
        #expect(store.state.canSkipSetup == false)
        await store.send(.skipTapped)
    }

    @Test func skipIsIgnoredWhileSaving() async {
        let store = TestStore(initialState: AlarmProvider.State(
            authorizationStatus: .authorized, isSaving: true
        )) {
            AlarmProvider()
        }

        await store.send(.skipTapped)
    }

    @Test func skippingAdvancesOnboardingWithoutCreatingAnAlarm() async throws {
        let defaults = try #require(UserDefaults(suiteName: "loop.alarm-setup.tests.\(UUID())"))
        let fixture = try OnboardingURLProtocol.fixture()
        let store = TestStore(initialState: OnboardingProvider.State(
            step: .alarm,
            alarm: AlarmProvider.State(authorizationStatus: .authorized)
        )) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0[AuthTokenStore.self].load = { "test-token" }
        }

        await store.send(.alarm(.skipTapped))
        await store.receive(.alarm(.delegate(.skipped))) {
            $0.step = .apps
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }
        #expect(store.state.alarm.alarm.scheduledID == nil)
    }
}

import ComposableArchitecture
import Foundation
import Testing
@testable import loop

@MainActor
struct AlarmFeatureTests {
    private let initialTime = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func appearingStartsTheClockAtTheCurrentTimeOnce() async {
        let store = TestStore(initialState: AlarmFeature.State()) {
            AlarmFeature()
        } withDependencies: {
            $0.date.now = initialTime
        }

        await store.send(.appeared) {
            $0.alarm.time = initialTime
            $0.hasInitializedTime = true
        }
        await store.send(.appeared)
    }

    @Test func savingSchedulesTheNextOccurrenceAndReplacesThePreviousAlarm() async {
        let previousID = UUID()
        let newID = UUID()
        let calendar = Calendar(identifier: .gregorian)
        var state = AlarmFeature.State(hasInitializedTime: true, authorizationStatus: .authorized)
        state.alarm.time = initialTime.addingTimeInterval(-60)
        state.alarm.scheduledID = previousID
        let scheduled = LockIsolated<(Date, UUID?)?>(nil)
        let store = TestStore(initialState: state) {
            AlarmFeature()
        } withDependencies: {
            $0.date.now = initialTime
            $0.calendar = calendar
            $0[AlarmClient.self].schedule = { date, replacing in
                scheduled.setValue((date, replacing))
                return newID
            }
        }
        let next = state.alarm.nextOccurrence(after: initialTime, calendar: calendar)!

        await store.send(.saveTapped) {
            $0.alarm.time = next
            $0.isSaving = true
        }
        await store.receive(.saveSucceeded(newID)) {
            $0.isSaving = false
            $0.alarm.scheduledID = newID
        }
        await store.receive(.delegate(.saved))
        #expect(scheduled.value?.0 == next)
        #expect(scheduled.value?.1 == previousID)
    }

    @Test func savingWithoutPermissionAsksFirstThenSchedules() async {
        let id = UUID()
        let clock = TestClock()
        let calendar = Calendar(identifier: .gregorian)
        var state = AlarmFeature.State(hasInitializedTime: true)
        state.alarm.time = initialTime.addingTimeInterval(60)
        let store = TestStore(initialState: state) {
            AlarmFeature()
        } withDependencies: {
            $0.date.now = initialTime
            $0.calendar = calendar
            $0[AlarmClient.self].requestAuthorization = {
                try? await clock.sleep(for: .seconds(1))
                return .authorized
            }
            $0[AlarmClient.self].schedule = { _, _ in id }
        }
        let next = state.alarm.nextOccurrence(after: initialTime, calendar: calendar)!

        await store.send(.saveTapped) { $0.authorizationStatus = .requesting }
        // A scene refresh while the system prompt is up must not clobber the request.
        await store.send(.authorizationChecked(.unknown))
        await clock.advance(by: .seconds(1))
        await store.receive(.authorizationResponse(.authorized)) {
            $0.authorizationStatus = .authorized
            $0.alarm.time = next
            $0.isSaving = true
        }
        await store.receive(.saveSucceeded(id)) {
            $0.isSaving = false
            $0.alarm.scheduledID = id
        }
        await store.receive(.delegate(.saved))
    }

    @Test(arguments: [false, true])
    func deniedPermissionExplainsHowToFixIt(alreadyDenied: Bool) async {
        let clock = TestClock()
        let store = TestStore(initialState: AlarmFeature.State(authorizationStatus: alreadyDenied ? .denied : .unknown)) {
            AlarmFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0[AlarmClient.self].requestAuthorization = { .denied }
        }

        if alreadyDenied {
            await store.send(.saveTapped) { $0.errorMessage = AlarmFeature.deniedMessage }
        } else {
            await store.send(.saveTapped) { $0.authorizationStatus = .requesting }
            await store.receive(.authorizationResponse(.denied)) {
                $0.authorizationStatus = .denied
                $0.errorMessage = AlarmFeature.deniedMessage
            }
        }
        await clock.advance(by: .seconds(3))
        await store.receive(.errorDismissed) { $0.errorMessage = nil }
    }
}

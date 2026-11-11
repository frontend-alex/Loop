import AlarmKit
import ComposableArchitecture
import Foundation

@Reducer
struct AlarmProvider {
    enum AuthorizationStatus: Equatable, Sendable {
        case unknown
        case requesting
        case authorized
        case denied
    }

    @ObservableState
    struct State: Equatable {
        var alarm = Alarm(
            scheduledID: nil,
            time: .now,
            isRepeating: false,
            repeatDays: [],
            label: "",
            sound: .default,
            snoozeEnabled: true
        )
        var hasInitializedTime = false
        var hasEditedTime = false
        var authorizationStatus: AuthorizationStatus = .unknown
        var isSaving = false
        var errorMessage: String?

        var canSkipSetup: Bool {
            !hasEditedTime
        }

        static func restored(from alarm: Alarm?) -> Self {
            var state = Self()
            state.alarm = alarm ?? state.alarm
            state.hasInitializedTime = alarm != nil
            switch AlarmManager.shared.authorizationState {
            case .notDetermined: state.authorizationStatus = .unknown
            case .authorized: state.authorizationStatus = .authorized
            case .denied: state.authorizationStatus = .denied
            @unknown default: state.authorizationStatus = .denied
            }
            return state
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case appeared
        case timeChanged(Date)
        case authorizationRefreshed
        case authorizationChecked(AuthorizationStatus)
        case authorizationRequested
        case authorizationSucceeded(Bool)
        case authorizationFailed(String)
        case permissionSkipped
        case skipTapped
        case saveTapped
        case saveSucceeded(UUID)
        case saveFailed(String)
        case errorDismissed
        case delegate(Delegate)

        enum Delegate: Equatable {
            case saved
            case skipped
        }
    }

    private nonisolated enum CancelID: Hashable, Sendable {
        case authorization
        case errorDismissal
    }

    @Dependency(\.continuousClock) private var clock
    @Dependency(\.date.now) private var now
    @Dependency(\.calendar) private var calendar

    private var dismissErrorAfterDelay: Effect<Action> {
        .run { [clock] send in
            try await clock.sleep(for: .seconds(3))
            await send(.errorDismissed)
        }
        .cancellable(id: CancelID.errorDismissal, cancelInFlight: true)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .appeared:
                state.hasEditedTime = false
                guard !state.hasInitializedTime else { return .none }
                state.alarm.time = now
                state.hasInitializedTime = true
                return .none

            case let .timeChanged(time):
                guard !state.isSaving else { return .none }
                if calendar.dateComponents([.hour, .minute], from: state.alarm.time)
                    != calendar.dateComponents([.hour, .minute], from: time) {
                    state.hasEditedTime = true
                }
                state.alarm.time = time
                return .none

            case .authorizationRefreshed:
                guard state.authorizationStatus != .requesting else { return .none }
                return .run { @MainActor send in
                    switch AlarmManager.shared.authorizationState {
                    case .notDetermined: send(.authorizationChecked(.unknown))
                    case .authorized: send(.authorizationChecked(.authorized))
                    case .denied: send(.authorizationChecked(.denied))
                    @unknown default: send(.authorizationChecked(.denied))
                    }
                }

            case let .authorizationChecked(status):
                guard state.authorizationStatus != .requesting else { return .none }
                state.authorizationStatus = status
                return .none

            case .authorizationRequested:
                guard state.authorizationStatus != .requesting else { return .none }
                state.authorizationStatus = .requesting
                state.errorMessage = nil
                return .run { @MainActor send in
                    do {
                        let status = try await AlarmManager.shared.requestAuthorization()
                        send(.authorizationSucceeded(status == .authorized))
                    } catch is CancellationError {
                    } catch {
                        send(.authorizationFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.authorization, cancelInFlight: true)

            case let .authorizationSucceeded(authorized):
                state.authorizationStatus = authorized ? .authorized : .denied
                return .none

            case let .authorizationFailed(message):
                state.authorizationStatus = .denied
                state.errorMessage = message
                return dismissErrorAfterDelay

            case .permissionSkipped:
                guard !state.isSaving else { return .none }
                if state.authorizationStatus == .requesting {
                    state.authorizationStatus = .unknown
                }
                return .merge(
                    .cancel(id: CancelID.authorization),
                    .cancel(id: CancelID.errorDismissal),
                    .send(.delegate(.skipped))
                )

            case .skipTapped:
                guard state.canSkipSetup, !state.isSaving else { return .none }
                return .merge(
                    .cancel(id: CancelID.errorDismissal),
                    .send(.delegate(.skipped))
                )

            case .saveTapped:
                guard state.authorizationStatus == .authorized, !state.isSaving else {
                    return .none
                }
                guard let date = state.alarm.nextOccurrence(after: now, calendar: calendar) else {
                    state.errorMessage = "Could not determine the next alarm time."
                    return dismissErrorAfterDelay
                }
                state.alarm.time = date
                state.isSaving = true
                state.errorMessage = nil
                return .merge(
                    .cancel(id: CancelID.errorDismissal),
                    .run { [alarm = state.alarm] send in
                        do {
                            let scheduler = AlarmScheduler()
                            if let oldID = alarm.scheduledID {
                                try await scheduler.cancelAlarm(id: oldID)
                            }
                            let id = try await scheduler.setAlarm(at: alarm.time)
                            await send(.saveSucceeded(id))
                        } catch {
                            await send(.saveFailed(error.localizedDescription))
                        }
                    }
                )

            case let .saveSucceeded(id):
                state.isSaving = false
                state.errorMessage = nil
                state.alarm.scheduledID = id
                return .send(.delegate(.saved))

            case let .saveFailed(message):
                state.isSaving = false
                state.errorMessage = message
                return dismissErrorAfterDelay

            case .errorDismissed:
                state.errorMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

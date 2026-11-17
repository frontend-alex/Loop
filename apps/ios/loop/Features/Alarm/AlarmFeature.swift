import ComposableArchitecture
import Foundation

@Reducer
struct AlarmFeature {
    @ObservableState
    struct State: Equatable {
        var alarm = Alarm()
        var hasInitializedTime = false
        var authorizationStatus = PermissionStatus.unknown
        var isSaving = false
        var errorMessage: String?

        static func restored(from alarm: Alarm?) -> Self {
            Self(alarm: alarm ?? Alarm(), hasInitializedTime: alarm != nil)
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case appeared
        case authorizationRefreshed
        case authorizationChecked(PermissionStatus)
        case authorizationResponse(PermissionStatus)
        case saveTapped
        case saveSucceeded(UUID)
        case saveFailed(String)
        case errorDismissed
        case delegate(Delegate)

        enum Delegate: Equatable {
            case saved
        }
    }

    nonisolated enum CancelID { case errorDismissal }

    @Dependency(AlarmClient.self) var alarmClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .delegate:
                return .none

            case .appeared:
                guard !state.hasInitializedTime else { return .none }
                state.alarm.time = now
                state.hasInitializedTime = true
                return .none

            case .authorizationRefreshed:
                return .run { send in
                    await send(.authorizationChecked(alarmClient.authorizationStatus()))
                }

            case let .authorizationChecked(status):
                // The system prompt deactivates the scene; ignore refreshes while it is up.
                guard state.authorizationStatus != .requesting else { return .none }
                state.authorizationStatus = status
                return .none

            case let .authorizationResponse(status):
                state.authorizationStatus = status
                return status == .authorized ? schedule(&state) : showError(Self.deniedMessage, &state)

            case .saveTapped:
                guard !state.isSaving else { return .none }
                switch state.authorizationStatus {
                case .authorized:
                    return schedule(&state)
                case .unknown:
                    state.authorizationStatus = .requesting
                    return .run { send in
                        await send(.authorizationResponse(alarmClient.requestAuthorization()))
                    }
                case .denied:
                    return showError(Self.deniedMessage, &state)
                case .requesting:
                    return .none
                }

            case let .saveSucceeded(id):
                state.isSaving = false
                state.errorMessage = nil
                state.alarm.scheduledID = id
                return .send(.delegate(.saved))

            case let .saveFailed(message):
                state.isSaving = false
                return showError(message, &state)

            case .errorDismissed:
                state.errorMessage = nil
                return .none
            }
        }
    }

    static let deniedMessage = "Alarm access is off. Turn it on in Settings to set an alarm."

    private func schedule(_ state: inout State) -> Effect<Action> {
        guard let date = state.alarm.nextOccurrence(after: now, calendar: calendar) else {
            return showError("Could not determine the next alarm time.", &state)
        }
        state.alarm.time = date
        state.isSaving = true
        state.errorMessage = nil
        return .merge(
            .cancel(id: CancelID.errorDismissal),
            .run { [alarm = state.alarm] send in
                do {
                    await send(.saveSucceeded(try await alarmClient.schedule(alarm.time, alarm.scheduledID)))
                } catch {
                    await send(.saveFailed(error.localizedDescription))
                }
            }
        )
    }

    private func showError(_ message: String, _ state: inout State) -> Effect<Action> {
        state.errorMessage = message
        return .run { send in
            try await clock.sleep(for: .seconds(3))
            await send(.errorDismissed)
        }
        .cancellable(id: CancelID.errorDismissal, cancelInFlight: true)
    }
}

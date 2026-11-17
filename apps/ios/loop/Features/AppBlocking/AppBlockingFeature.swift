import ComposableArchitecture
import FamilyControls
import Foundation

/// A `FamilyActivitySelection`, JSON-encoded for the onboarding draft.
nonisolated struct AppSelection: Codable, Equatable, Sendable {
    let encodedSelection: Data
}

@Reducer
struct AppBlockingFeature {
    @ObservableState
    struct State: Equatable {
        var authorizationStatus = PermissionStatus.unknown
        var selection = FamilyActivitySelection()
        var savedSelection: AppSelection?
        var errorMessage: String?

        static func restored(from savedSelection: AppSelection?) -> Self {
            var state = Self(savedSelection: savedSelection)
            guard let savedSelection else { return state }
            do {
                state.selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: savedSelection.encodedSelection)
            } catch {
                state.savedSelection = nil
                state.errorMessage = "Could not restore selected apps: \(error.localizedDescription)"
            }
            return state
        }
    }

    enum Action: Equatable {
        case task
        case authorizationRequested
        case authorizationSucceeded(Bool)
        case authorizationFailed(String)
        case permissionSkipped
        case selectionChanged(FamilyActivitySelection)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case skipped
        }
    }

    nonisolated enum CancelID { case authorization }

    @Dependency(AppBlockingClient.self) var appBlockingClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                guard state.authorizationStatus == .unknown else { return .none }
                return .send(.authorizationRequested)

            case .authorizationRequested:
                guard state.authorizationStatus != .authorized else { return .none }
                state.authorizationStatus = .requesting
                state.errorMessage = nil
                return .run { send in
                    do {
                        await send(.authorizationSucceeded(try await appBlockingClient.requestAuthorization()))
                    } catch is CancellationError {
                    } catch {
                        await send(.authorizationFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.authorization, cancelInFlight: true)

            case let .authorizationSucceeded(authorized):
                state.authorizationStatus = authorized ? .authorized : .denied
                return .none

            case let .authorizationFailed(message):
                state.authorizationStatus = .denied
                state.errorMessage = message
                return .none

            case .permissionSkipped:
                if state.authorizationStatus == .requesting {
                    state.authorizationStatus = .unknown
                }
                return .merge(.cancel(id: CancelID.authorization), .send(.delegate(.skipped)))

            case let .selectionChanged(selection):
                state.selection = selection
                do {
                    state.savedSelection = AppSelection(encodedSelection: try JSONEncoder().encode(selection))
                    state.errorMessage = nil
                } catch {
                    state.errorMessage = "Could not save selected apps: \(error.localizedDescription)"
                }
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

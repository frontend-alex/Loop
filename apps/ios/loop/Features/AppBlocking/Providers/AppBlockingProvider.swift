import ComposableArchitecture
import FamilyControls
import Foundation

@Reducer
struct AppBlockingProvider {
    enum AuthorizationStatus: Equatable {
        case unknown
        case requesting
        case authorized
        case denied
    }

    @ObservableState
    struct State: Equatable {
        var authorizationStatus: AuthorizationStatus = .unknown
        var selection = FamilyActivitySelection()
        var savedSelection: AppSelection?
        var isSaving = false
        var errorMessage: String?

        static func restored(from savedSelection: AppSelection?) -> Self {
            var state = Self()
            
            #if DEBUG
            state.authorizationStatus = .requesting
            #else
            switch AuthorizationCenter.shared.authorizationStatus {
            case .notDetermined: state.authorizationStatus = .unknown
            case .approved: state.authorizationStatus = .authorized
            case .denied: state.authorizationStatus = .denied
            @unknown default: state.authorizationStatus = .denied
            }
            #endif
            
            
            guard let savedSelection else { return state }

            do {
                let selection = try JSONDecoder().decode(
                    FamilyActivitySelection.self,
                    from: savedSelection.encodedSelection
                )
                state.selection = selection
                state.savedSelection = savedSelection
            } catch {
                state.errorMessage = "Could not restore selected apps: \(error.localizedDescription)"
            }
            return state
        }
    }

    enum Action: Equatable {
        case selectionChanged(FamilyActivitySelection)
        case task
        case authorizationRequested
        case authorizationSucceeded(Bool)
        case authorizationFailed(String)
        case permissionSkipped
        case selectionSaved(AppSelection)
        case selectionSaveFailed(String)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case skipped
        }
    }

    private nonisolated enum CancelID: Hashable, Sendable {
        case authorization
        case saveSelection
    }

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
                        #if DEBUG
                        let authorized = try await _AppBlockingService.requestAuthorization()
                        #else
                        let authorized = try await AppBlockingService.requestAuthorization()
                        #endif
                        await send(.authorizationSucceeded(authorized))
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
                return .merge(
                    .cancel(id: CancelID.authorization),
                    .send(.delegate(.skipped))
                )

            case let .selectionChanged(selection):
                state.selection = selection
                state.isSaving = true
                state.errorMessage = nil
                return .run { @MainActor send in
                    do {
                        let saved = AppSelection(encodedSelection: try JSONEncoder().encode(selection))
                        UserDefaults.standard.set(saved.encodedSelection, forKey: "app-blocking.selection")
                        send(.selectionSaved(saved))
                    } catch {
                        send(.selectionSaveFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.saveSelection, cancelInFlight: true)

            case let .selectionSaved(selection):
                state.savedSelection = selection
                state.isSaving = false
                return .none

            case let .selectionSaveFailed(message):
                state.isSaving = false
                state.errorMessage = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

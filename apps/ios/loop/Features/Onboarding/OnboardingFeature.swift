import ComposableArchitecture
import Foundation

/// The onboarding flow. Every change is saved on the device right away; the draft is uploaded
/// each time the user moves forward a step (and on finish). A pending upload survives relaunches
/// and is retried when back online, until the server accepts it.
@Reducer
struct OnboardingFeature {
    static let draftKey = "onboarding.draft"
    static let completedKey = "onboarding.completed"
    static let pendingSyncKey = "onboarding.pending-sync"

    nonisolated enum SyncOperation: String, Sendable {
        case update
        case complete
    }

    nonisolated enum CancelID: CaseIterable {
        case connectivity
        case sync
        case retry
    }

    @ObservableState
    struct State: Equatable {
        var userID: Int?
        var questionIndex = 0
        var step = OnboardingStep.questions
        var isNavigatingBack = false
        var answers: [String: QuestionAnswer] = [:]
        var selectedTaskIDs: Set<String> = []
        var alarm = AlarmFeature.State()
        var appBlocking = AppBlockingFeature.State()
        var isCompleted = false
        var persistenceErrorMessage: String?
        var isConnected = true
        var pendingSync: SyncOperation?

        var question: Question { Question.all[questionIndex] }

        /// The position in the flow: one page per question, then alarm, apps, tasks and summary.
        var currentStep: Int {
            switch step {
            case .questions: questionIndex
            case .alarm: Question.all.count
            case .apps: Question.all.count + 1
            case .tasks: Question.all.count + 2
            case .summary: Question.all.count + 3
            }
        }

        static var stepCount: Int { Question.all.count + 3 }

        var draft: OnboardingDraft {
            OnboardingDraft(
                step: step,
                questionIndex: questionIndex,
                answers: answers,
                alarm: alarm.alarm,
                distractingApps: appBlocking.savedSelection.map { [$0] } ?? [],
                taskIDs: selectedTaskIDs
            )
        }

        func storageKey(_ key: String) -> String {
            userID.map { "user.\($0).\(key)" } ?? key
        }

        /// Restores a user's saved draft. A flow completed on this device stays completed
        /// while its completion is still waiting to reach the server.
        static func restored(from defaults: UserDefaults, userID: Int? = nil, isCompleted: Bool? = nil) -> Self {
            var state = Self(userID: userID)
            state.pendingSync = defaults.string(forKey: state.storageKey(pendingSyncKey)).flatMap(SyncOperation.init)
            let completedLocally = defaults.bool(forKey: state.storageKey(completedKey))
            state.isCompleted = (isCompleted ?? completedLocally) || (completedLocally && state.pendingSync == .complete)

            guard !state.isCompleted || state.pendingSync != nil,
                  let data = defaults.data(forKey: state.storageKey(draftKey))
            else { return state }

            do {
                let draft = try JSONDecoder().decode(OnboardingDraft.self, from: data)
                state.step = draft.step
                state.questionIndex = min(max(draft.questionIndex, 0), Question.all.count - 1)
                state.answers = draft.answers
                state.selectedTaskIDs = draft.taskIDs
                state.alarm = .restored(from: draft.alarm)
                state.appBlocking = .restored(from: draft.distractingApps.first)
            } catch {
                state.persistenceErrorMessage = "Could not restore your setup. Please start again."
            }
            return state
        }
    }

    enum Action: Equatable {
        case task
        case connectivityChanged(Bool)
        case syncPending
        case singleAnswerSelected(String)
        case timeAnswerSelected(Date)
        case taskToggled(WakeUpTask.ID)
        case alarm(AlarmFeature.Action)
        case appBlocking(AppBlockingFeature.Action)
        case nextTapped
        case backTapped
        /// Jumps back to an earlier step from the summary to change it.
        case editTapped(OnboardingStep)
        case finishTapped
        case syncSucceeded(SyncOperation)
        case syncFailed
        case authenticationRequired
        case delegate(Delegate)

        enum Delegate: Equatable {
            case completed
        }
    }

    @Dependency(APIClient.self) var apiClient
    @Dependency(NetworkMonitor.self) var networkMonitor
    @Dependency(\.continuousClock) var clock
    @Dependency(\.defaultAppStorage) var defaults

    var body: some Reducer<State, Action> {
        CombineReducers {
            Scope(state: \.alarm, action: \.alarm) { AlarmFeature() }
            Scope(state: \.appBlocking, action: \.appBlocking) { AppBlockingFeature() }
            Reduce(core)
        }
        .onChange(of: \.draft) { _, state in
            guard !state.isCompleted else { return .none }
            _ = saveDraft(&state)
            return .none
        }
        .onChange(of: \.currentStep) { previousStep, state in
            guard !state.isCompleted, state.currentStep > previousStep else { return .none }
            return queueSync(.update, &state)
        }
    }

    private func core(_ state: inout State, _ action: Action) -> Effect<Action> {
        let canNavigate = !state.isCompleted && !state.alarm.isSaving

        switch action {
        case .task:
            return .merge(
                sync(&state),
                .run { [networkMonitor] send in
                    for await isConnected in networkMonitor.updates() {
                        await send(.connectivityChanged(isConnected))
                    }
                }
                .cancellable(id: CancelID.connectivity, cancelInFlight: true)
            )

        case let .connectivityChanged(isConnected):
            state.isConnected = isConnected
            return sync(&state)

        case .syncPending:
            return sync(&state)

        case let .singleAnswerSelected(option):
            state.answers[state.question.id] = .single(option)
            return .none

        case let .timeAnswerSelected(date):
            state.answers[state.question.id] = .time(date)
            return .none

        case let .taskToggled(id):
            if state.selectedTaskIDs.remove(id) == nil { state.selectedTaskIDs.insert(id) }
            return .none

        case .alarm(.delegate(.saved)):
            guard !state.isCompleted else { return .none }
            state.isNavigatingBack = false
            state.step = .apps
            return .none

        case .appBlocking(.delegate(.skipped)):
            guard !state.isCompleted else { return .none }
            state.isNavigatingBack = false
            state.step = .tasks
            return .none

        case .nextTapped:
            guard canNavigate else { return .none }
            state.isNavigatingBack = false
            switch state.step {
            case .questions where state.questionIndex < Question.all.count - 1:
                state.questionIndex += 1
            case .questions:
                // Start the alarm at the workday wake-up time, unless the alarm was already set.
                if !state.alarm.hasInitializedTime, case let .time(date) = state.answers[Question.wakeTimeID] {
                    state.alarm.alarm.time = date
                    state.alarm.hasInitializedTime = true
                }
                state.step = .alarm
            case .alarm:
                return .send(.alarm(.saveTapped))
            case .apps:
                guard state.appBlocking.authorizationStatus == .authorized,
                      state.appBlocking.errorMessage == nil else { return .none }
                state.step = .tasks
            case .tasks:
                guard !state.selectedTaskIDs.isEmpty else { return .none }
                state.step = .summary
            case .summary:
                break
            }
            return .none

        case .backTapped:
            guard canNavigate, state.currentStep > 0 else { return .none }
            state.isNavigatingBack = true
            switch state.step {
            case .questions: state.questionIndex -= 1
            case .alarm: state.step = .questions
            case .apps: state.step = .alarm
            case .tasks: state.step = .apps
            case .summary: state.step = .tasks
            }
            return .none

        case let .editTapped(target):
            guard canNavigate, target != state.step else { return .none }
            state.isNavigatingBack = true
            state.step = target
            return .none

        case .finishTapped:
            guard canNavigate, state.step == .summary, saveDraft(&state) else { return .none }
            state.isCompleted = true
            defaults.set(true, forKey: state.storageKey(Self.completedKey))
            return .merge(queueSync(.complete, &state), .send(.delegate(.completed)))

        case let .syncSucceeded(operation):
            guard operation == state.pendingSync else { return .none }
            state.pendingSync = nil
            defaults.removeObject(forKey: state.storageKey(Self.pendingSyncKey))
            if operation == .complete {
                defaults.removeObject(forKey: state.storageKey(Self.draftKey))
            }
            return .none

        case .syncFailed:
            guard state.isConnected else { return .none }
            return .run { send in
                try await clock.sleep(for: .seconds(30))
                await send(.syncPending)
            }
            .cancellable(id: CancelID.retry, cancelInFlight: true)

        case .authenticationRequired:
            // An invalid token is not a connectivity failure: keep the draft, but don't retry or log out.
            return .none

        case .alarm, .appBlocking, .delegate:
            return .none
        }
    }

    private func saveDraft(_ state: inout State) -> Bool {
        do {
            defaults.set(try JSONEncoder().encode(state.draft), forKey: state.storageKey(Self.draftKey))
            state.persistenceErrorMessage = nil
            return true
        } catch {
            state.persistenceErrorMessage = "Could not save your progress: \(error.localizedDescription)"
            return false
        }
    }

    private func queueSync(_ operation: SyncOperation, _ state: inout State) -> Effect<Action> {
        if state.pendingSync != .complete {
            state.pendingSync = operation
        }
        defaults.set(state.pendingSync?.rawValue, forKey: state.storageKey(Self.pendingSyncKey))
        return sync(&state)
    }

    /// Uploads the latest draft. A newer upload cancels the one in flight, so the response
    /// that arrives always describes the current draft.
    private func sync(_ state: inout State) -> Effect<Action> {
        guard state.isConnected, let operation = state.pendingSync else {
            return .cancel(id: CancelID.sync)
        }
        let body = OnboardingRequest(answers: state.answers, currentStep: state.currentStep)
        return .merge(
            .cancel(id: CancelID.retry),
            .run { send in
                do {
                    try await apiClient.updateOnboarding(operation, body)
                    await send(.syncSucceeded(operation))
                } catch APIClient.Failure.unauthorized {
                    await send(.authenticationRequired)
                } catch {
                    await send(.syncFailed)
                }
            }
            .cancellable(id: CancelID.sync, cancelInFlight: true)
        )
    }
}

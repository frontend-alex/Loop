//
//  Onboarding.Provider.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//

import Foundation
import ComposableArchitecture

@Reducer
struct OnboardingProvider {
    static let draftKey = "onboarding.draft"
    static let completedKey = "onboarding.completed"
    static let pendingSyncKey = "onboarding.pending-sync"

    var defaults: UserDefaults = .standard
    var session: URLSession = .shared
    var apiBaseURL: URL = AppEnvironment.current.apiBaseURL

    @Dependency(AuthTokenStore.self) private var authTokenStore

    enum SyncOperation: String, Sendable {
        case update
        case complete
    }

    @ObservableState
    struct State: Equatable {
        var userID: Int?
        var questions = Question.all
        var questionIndex = 0
        var step: OnboardingStep = .questions
        var isNavigatingBack = false
        var answers: [String: QuestionAnswer] = [:]
        var tasks: [TaskItem] = []
        var alarm = AlarmProvider.State()
        var appBlocking = AppBlockingProvider.State()
        var isCompleted = false
        var persistenceErrorMessage: String?
        var isSyncing = false
        var syncErrorMessage: String?
        var pendingSync: SyncOperation?

        var currentStep: Int {
            switch step {
            case .questions: questionIndex
            case .alarm: questions.count
            case .apps: questions.count + 1
            case .tasks: questions.count + 2
            case .summary: questions.count + 3
            }
        }

        var isNavigationLocked: Bool {
            pendingSync != nil || isSyncing || syncErrorMessage != nil
        }

        var draft: OnboardingDraft {
            OnboardingDraft(
                step: step,
                questionIndex: questionIndex,
                answers: answers,
                alarm: alarm.alarm,
                distractingApps: appBlocking.savedSelection.map { [$0] } ?? [],
                tasks: tasks
            )
        }

        func storageKey(_ key: String) -> String {
            guard let userID else { return key }
            return "user.\(userID).\(key)"
        }

        static func restored(
            from defaults: UserDefaults = .standard,
            userID: Int? = nil,
            isCompleted: Bool? = nil
        ) -> Self {
            var state = Self(userID: userID)
            state.isCompleted = isCompleted
                ?? defaults.bool(forKey: state.storageKey(OnboardingProvider.completedKey))
            guard !state.isCompleted,
                  let data = defaults.data(forKey: state.storageKey(OnboardingProvider.draftKey)) else { return state }

            do {
                let draft = try JSONDecoder().decode(OnboardingDraft.self, from: data)
                state.step = draft.step
                state.questionIndex = min(max(draft.questionIndex, 0), max(state.questions.count - 1, 0))
                state.answers = draft.answers
                state.tasks = draft.tasks
                state.alarm = .restored(from: draft.alarm)
                state.appBlocking = .restored(from: draft.distractingApps.first)
                state.pendingSync = defaults.string(forKey: state.storageKey(OnboardingProvider.pendingSyncKey))
                    .flatMap(SyncOperation.init(rawValue:))
            } catch {
                state.persistenceErrorMessage = "Could not restore your setup. Please start again."
            }
            return state
        }
    }

    enum Action: Equatable {
        case task
        case singleAnswerSelected(String)
        case multipleAnswerToggled(String)
        case timeAnswerSelected(Date)

        case alarm(AlarmProvider.Action)
        case appBlocking(AppBlockingProvider.Action)
        
        case taskAdded(TaskItem)

        case nextTapped
        case backTapped
        case finishTapped
        case retrySyncTapped
        case syncSucceeded
        case syncFailed(String)
        case authenticationRequired

        case delegate(Delegate)

        enum Delegate: Equatable {
            case completed
            case authenticationRequired
        }
    }

    var body: some Reducer<State, Action> {
        content
            .onChange(of: \.draft) { _, state in
                guard !state.isCompleted else { return .none }

                do {
                    let data = try JSONEncoder().encode(state.draft)
                    defaults.set(data, forKey: state.storageKey(Self.draftKey))
                    state.persistenceErrorMessage = nil
                } catch {
                    state.persistenceErrorMessage = "Could not save your progress: \(error.localizedDescription)"
                }
                return .none
            }
    }

    @ReducerBuilder<State, Action>
    private var content: some Reducer<State, Action> {
        Scope(state: \.alarm, action: \.alarm) {
            AlarmProvider()
        }

        Scope(state: \.appBlocking, action: \.appBlocking) {
            AppBlockingProvider()
        }

        Reduce { state, action in
            switch action {
            case .task, .retrySyncTapped:
                guard let operation = state.pendingSync else { return .none }
                return syncProgress(&state, operation: operation)

            case let .singleAnswerSelected(option):
                let question = state.questions[state.questionIndex]
                state.answers[question.id] = .single(option)
                return .none

            case let .multipleAnswerToggled(option):
                let question = state.questions[state.questionIndex]
                var selected: Set<String>

                switch state.answers[question.id] {
                case let .multiple(values):
                    selected = values
                default:
                    selected = []
                }

                if selected.contains(option) {
                    selected.remove(option)
                } else {
                    selected.insert(option)
                }

                state.answers[question.id] = .multiple(selected)
                return .none

            case let .timeAnswerSelected(date):
                let question = state.questions[state.questionIndex]
                state.answers[question.id] = .time(date)
                return .none

            case .alarm(.delegate(.saved)), .alarm(.delegate(.skipped)):
                guard !state.isNavigationLocked, !state.isCompleted else { return .none }
                state.isNavigatingBack = false
                state.step = .apps
                return syncProgress(&state)

            case .appBlocking(.delegate(.skipped)):
                guard !state.isNavigationLocked, !state.isCompleted else { return .none }
                state.isNavigatingBack = false
                state.step = .tasks
                return syncProgress(&state)

            case let .taskAdded(task):
                state.tasks.append(task)
                return .none

            case .nextTapped:
                guard !state.isNavigationLocked, !state.isCompleted,
                      !state.alarm.isSaving, !state.appBlocking.isSaving else { return .none }
                state.isNavigatingBack = false
                switch state.step {
                case .questions:
                    if state.questionIndex < state.questions.count - 1 {
                        state.questionIndex += 1
                    } else {
                        state.step = .alarm
                    }
                case .alarm:
                    return .send(.alarm(.saveTapped))
                case .apps:
                    guard state.appBlocking.authorizationStatus == .authorized,
                          state.appBlocking.errorMessage == nil else { return .none }
                    state.step = .tasks
                case .tasks:
                    state.step = .summary
                case .summary:
                    return .none
                }

                return syncProgress(&state)

            case .backTapped:
                guard !state.isNavigationLocked, !state.isCompleted,
                      !state.alarm.isSaving, !state.appBlocking.isSaving,
                      state.currentStep > 0 else { return .none }
                state.isNavigatingBack = true
                switch state.step {
                case .questions:
                    if state.questionIndex > 0 {
                        state.questionIndex -= 1
                    }
                case .alarm:
                    state.step = .questions
                case .apps:
                    state.step = .alarm
                case .tasks:
                    state.step = .apps
                case .summary:
                    state.step = .tasks
                }

                return .none

            case .finishTapped:
                guard state.step == .summary,
                      !state.isNavigationLocked, !state.isCompleted,
                      !state.alarm.isSaving, !state.appBlocking.isSaving else { return .none }
                return syncProgress(&state, operation: .complete)

            case .syncSucceeded:
                let completed = state.pendingSync == .complete
                state.isSyncing = false
                state.syncErrorMessage = nil
                state.pendingSync = nil
                guard completed else {
                    defaults.removeObject(forKey: state.storageKey(Self.pendingSyncKey))
                    return .none
                }

                state.isCompleted = true
                state.persistenceErrorMessage = nil
                defaults.set(true, forKey: state.storageKey(Self.completedKey))
                defaults.removeObject(forKey: state.storageKey(Self.draftKey))
                defaults.removeObject(forKey: state.storageKey(Self.pendingSyncKey))
                return .send(.delegate(.completed))

            case let .syncFailed(message):
                state.isSyncing = false
                state.syncErrorMessage = message
                return .none

            case .authenticationRequired:
                state.isSyncing = false
                state.syncErrorMessage = "Please sign in again to save your progress."
                return .send(.delegate(.authenticationRequired))

            case .alarm, .appBlocking, .delegate:
                return .none
            }
        }
    }

    private func syncProgress(
        _ state: inout State,
        operation: SyncOperation = .update
    ) -> Effect<Action> {
        guard !state.isSyncing, !state.isCompleted else { return .none }
        state.isSyncing = true
        state.syncErrorMessage = nil
        state.pendingSync = operation
        defaults.set(operation.rawValue, forKey: state.storageKey(Self.pendingSyncKey))

        let body = OnboardingRequest(answers: state.answers, currentStep: state.currentStep)
        return .run { [authTokenStore, session, apiBaseURL] send in
            do {
                guard let token = try await authTokenStore.load(), !token.isEmpty else {
                    throw URLError(.userAuthenticationRequired)
                }
                try await Self.sendProgress(
                    body,
                    token: token,
                    operation: operation,
                    session: session,
                    baseURL: apiBaseURL
                )
                await send(.syncSucceeded)
            } catch let error as URLError where error.code == .userAuthenticationRequired {
                await send(.authenticationRequired)
            } catch {
                await send(.syncFailed(error.localizedDescription))
            }
        }
    }

    static func sendProgress(
        _ body: OnboardingRequest,
        token: String,
        operation: SyncOperation,
        session: URLSession,
        baseURL: URL
    ) async throws {
        guard baseURL.host != nil, baseURL.scheme == "https" || (baseURL.scheme == "http" && AppEnvironment.current.name == .development)
        else { throw URLError(.badURL) }

        let url = baseURL.appendingPathComponent("onboarding")
            .appendingPathComponent(operation.rawValue)
        var request = URLRequest(url: url)
        
        request.httpMethod = "PATCH"
        request.timeoutInterval = 20
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if response.statusCode == 401 {
            throw URLError(.userAuthenticationRequired)
        }
        guard response.statusCode == 204 else {
            throw NSError(domain: "Onboarding", code: response.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Could not save onboarding (HTTP \(response.statusCode)). Please retry."
            ])
        }
    }
}

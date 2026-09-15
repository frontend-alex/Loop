//
//  Onboarding.Provider.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//

import Foundation
import ComposableArchitecture
import AlarmKit

@Reducer
struct OnboardingProvider {
    @ObservableState
    struct State: Equatable {
        enum Step: Equatable {
            case questions
            case alarm
            case apps
            case tasks
            case summary
        }

        var questions = Question.all
        var questionIndex = 0
        var step: Step = .questions
        var draft = OnboardingDraft()
        var isSaving = false
        var errorMessage: String?

        var alarmAuthorizationStatus: AlarmAuthorizationStatus = .unknown
        var alarmErrorMessage: String?

        var appsAuthorizationStatus: AppsAuthorizationStatus = .unknown
        var appsErrorMessage: String?
        var isSavingApps = false
    }

    enum Action {
        case singleAnswerSelected(String)
        case multipleAnswerToggled(String)
        case timeAnswerSelected(Date)

        case alarmSelected(Alarm)
        case alarmAuthorizationChecked(AlarmAuthorizationStatus)
        case alarmAuthorizationRequested
        case alarmAuthorizationSucceeded(Bool)
        case alarmAuthorizationFailed(String)
        case alarmPermissionSkipped
        case alarmSetTapped
        case alarmSetSucceeded(UUID)
        case alarmSetFailed(String)

        case appsSelected([AppSelection])
        
        case appsAuthorizationRequested
        case appsAuthorizationSucceeded(Bool)
        case appsAuthorizationFailed(String)
        case appsPermissionSkipped
        case appsSelectionChanged(AppSelection)
        case appsSelectionSaveFailed(String)
        
        case taskAdded(TaskItem)

        case nextTapped
        case backTapped
        case finishTapped

        case delegate(Delegate)

        enum Delegate {
            case completed
        }
    }
    enum AppsAuthorizationStatus: Equatable {
        case unknown
        case requesting
        case authorized
        case denied
    }

    enum AlarmAuthorizationStatus: Equatable {
        case unknown
        case requesting
        case authorized
        case denied
    }
    


    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .singleAnswerSelected(option):
                let question = state.questions[state.questionIndex]
                state.draft.answers[question.id] = .single(option)
                return .none

            case let .multipleAnswerToggled(option):
                let question = state.questions[state.questionIndex]
                var selected: Set<String>

                switch state.draft.answers[question.id] {
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

                state.draft.answers[question.id] = .multiple(selected)
                return .none

            case let .timeAnswerSelected(date):
                let question = state.questions[state.questionIndex]
                state.draft.answers[question.id] = .time(date)
                return .none

            case let .alarmSelected(alarm):
                var updatedAlarm = alarm
                updatedAlarm.scheduledID = state.draft.alarm?.scheduledID
                state.draft.alarm = updatedAlarm
                return .none

            case let .alarmAuthorizationChecked(status):
                state.alarmAuthorizationStatus = status
                return .none

            case .alarmAuthorizationRequested:
                state.alarmAuthorizationStatus = .requesting
                state.alarmErrorMessage = nil
                return .run { @MainActor send in
                    do {
                        let status = try await AlarmManager.shared.requestAuthorization()
                        await send(.alarmAuthorizationSucceeded(status == .authorized))
                    } catch {
                        await send(.alarmAuthorizationFailed(error.localizedDescription))
                    }
                }

            case let .alarmAuthorizationSucceeded(authorized):
                state.alarmAuthorizationStatus = authorized ? .authorized : .denied
                return .none

            case let .alarmAuthorizationFailed(message):
                state.alarmAuthorizationStatus = .denied
                state.alarmErrorMessage = message
                return .none

            case .alarmPermissionSkipped:
                state.step = .apps
                return .none

            case .alarmSetTapped:
                guard let alarm = state.draft.alarm else {
                    return .none
                }

                state.isSaving = true

                return .run { [alarm] send in
                    do {
                        if let oldID = alarm.scheduledID {
                            try await AlarmScheduler.cancelAlarm(id: oldID)
                        }

                        let newID = try await AlarmScheduler.setAlarm(at: alarm.time)
                        await send(.alarmSetSucceeded(newID))
                    } catch {
                        await send(.alarmSetFailed(error.localizedDescription))
                    }
                }

            case let .alarmSetSucceeded(id):
                state.isSaving = false
                state.draft.alarm?.scheduledID = id
                state.step = .apps
                return .none

            case let .alarmSetFailed(message):
                state.isSaving = false
                state.errorMessage = message
                return .none

            case let .appsSelected(apps):
                state.draft.distractingApps = apps
                return .none

            case .appsAuthorizationRequested:
                state.appsAuthorizationStatus = .requesting
                state.appsErrorMessage = nil
                return .none

            case let .appsAuthorizationSucceeded(authorized):
                state.appsAuthorizationStatus = authorized ? .authorized : .denied
                return .none

            case let .appsAuthorizationFailed(message):
                state.appsAuthorizationStatus = .denied
                state.appsErrorMessage = message
                return .none

            case let .appsSelectionChanged(selection):
                state.draft.distractingApps = [selection]
                state.appsErrorMessage = nil
                return .none

            case let .appsSelectionSaveFailed(message):
                state.appsErrorMessage = message
                return .none

            case .appsPermissionSkipped:
                state.step = .tasks
                return .none

            case let .taskAdded(task):
                state.draft.tasks.append(task)
                return .none

            case .nextTapped:
                switch state.step {
                case .questions:
                    if state.questionIndex < state.questions.count - 1 {
                        state.questionIndex += 1
                    } else {
                        state.step = .alarm
                    }
                case .alarm:
                    state.step = .apps
                case .apps:
                    state.step = .tasks
                case .tasks:
                    state.step = .summary
                case .summary:
                    break
                }

                return .none

            case .backTapped:
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
                return .send(.delegate(.completed))

            case .delegate:
                return .none
            }
        }
    }
}

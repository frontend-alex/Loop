//
//  Onboarding.Feature.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//
import Foundation
import ComposableArchitecture

@Reducer
struct OnboardingFeature {
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
        var step: Step = .alarm
        var draft = OnboardingDraft()
        var isSaving = false
        var errorMessage: String?
    }

    enum Action {
        case singleAnswerSelected(String)
        case multipleAnswerToggled(String)
        case timeAnswerSelected(Date)

        case alarmSelected(Alarm)
        case appsSelected([AppSelection])
        case taskAdded(TaskItem)

        case nextTapped
        case backTapped
        case finishTapped

        case delegate(Delegate)

        enum Delegate {
            case completed
        }
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
                state.draft.alarm = alarm
                return .none

            case let .appsSelected(apps):
                state.draft.distractingApps = apps
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
                // The API submission will be added through an injected dependency.
                return .send(.delegate(.completed))

            case .delegate:
                return .none
            }
        }
    }
}

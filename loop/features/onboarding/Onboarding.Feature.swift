//
//  Onboarding.Feature.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//
import ComposableArchitecture

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        enum Step: Equatable {
            case alarm
            case apps
            case tasks
            case summary
        }

        var step: Step = .alarm
        var draft = OnboardingDraft()
        var isSaving = false
        var errorMessage: String?
    }

    enum Action {
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
                case .alarm:
                    break
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

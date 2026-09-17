import SwiftUI
import ComposableArchitecture

struct OnboardingView: View {
    let store: StoreOf<OnboardingProvider>

    @Environment(\.colorScheme) private var colorScheme

    private var adaptiveColor: Color {
        colorScheme == .light ? .black : .white
    }

    private var topBar: some View {
        HStack {
            AppButton(
                variant: .icon,
                tint: adaptiveColor,
                action: {
                    store.send(.backTapped)
                }
            ){
                Label("Back", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
            }
            .disabled(
                store.step == .questions &&
                store.questionIndex == 0
            )
            
            Spacer()
        }        
    }

    private var bottomBar: some View {
        AppButton(action: {
            switch store.step {
            case .alarm:
                _ = store.send(.alarmSetTapped)

            case .summary:
                _ = store.send(.finishTapped)

            default:
                _ = store.send(.nextTapped)
            }
        }) {
            Text(bottomButtonTitle)
        }
        .disabled(!canContinue || store.isSaving)
    }

    private var bottomButtonTitle: String {
        switch store.step {
        case .alarm:
            return "Set Alarm"

        case .summary:
            return "Finish"

        default:
            return "Continue"
        }
    }

    private var shouldShowBottomBar: Bool {
        switch store.step {
        case .alarm:
            return store.alarmAuthorizationStatus == .authorized
            
        case .apps:
            return store.appsAuthorizationStatus == .authorized

        default:
            return true
        }
    }

    private var canContinue: Bool {
        switch store.step {
        case .questions:
            guard store.questionIndex < store.questions.count else {
                return false
            }

            let question = store.questions[store.questionIndex]

            guard let answer = store.draft.answers[question.id] else {
                return false
            }

            switch answer {
            case let .multiple(values):
                return !values.isEmpty

            case .single, .time:
                return true
            }

        case .alarm:
            return store.draft.alarm != nil

        case .apps, .tasks, .summary:
            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.md) {
                topBar

                Group {
                    switch store.step {
                    case .questions:
                        QuestionsView(store: store)

                    case .alarm:
                        AlarmView(
                            store: store,
                            onAlarmChanged: { alarm in
                                store.send(.alarmSelected(alarm))
                            }
                        )

                    case .apps:
                        AppBlockingView(store: store)

                    case .tasks:
                        TasksView()

                    case .summary:
                        Text("Summary")
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
            }
            .safeAreaPadding(.horizontal, DesignSystem.Spacing.md)
            .toolbar(.hidden, for: .navigationBar)
            
            .safeAreaInset(edge: .bottom) {
                if shouldShowBottomBar {
                    bottomBar
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                }
            }
        }
    }
}

#Preview {
    OnboardingView(
        store: Store(
            initialState: OnboardingProvider.State(
                step: .questions,
                alarmAuthorizationStatus: .authorized
            )
        ) {
            OnboardingProvider()
        }
    )
}

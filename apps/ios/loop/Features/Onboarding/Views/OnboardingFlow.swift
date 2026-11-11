import SwiftUI
import ComposableArchitecture

struct OnboardingView: View {
    let store: StoreOf<OnboardingProvider>

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isSaving: Bool {
        store.alarm.isSaving || store.appBlocking.isSaving || store.isSyncing
    }

    private var canGoBack: Bool {
        shouldShowNavigationBars && !store.isNavigationLocked && !isSaving
            && (store.step != .questions || store.questionIndex > 0)
    }

    private var topBar: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            AppButton(
                variant: .secondary,
                size: .iconSmall,
                action: {
                    store.send(.backTapped)
                }
            ) {
                Label("Back", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
            }
            .disabled(!canGoBack)

            OnboardingProgress(store: store)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    private var bottomBar: some View {
        AppButton(action: {
            switch store.step {
            case .summary:
                _ = store.send(.finishTapped)

            default:
                _ = store.send(.nextTapped)
                print(store.step)
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isSaving {
                    ProgressView()
                }
                Text(bottomButtonTitle)
            }
        }
        .disabled(!canContinue || isSaving || store.isNavigationLocked)
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

    private var shouldShowNavigationBars: Bool {
        switch store.step {
        case .alarm:
            return store.alarm.authorizationStatus == .authorized
            
        case .apps:
            return store.appBlocking.authorizationStatus == .authorized

        case .questions, .tasks, .summary:
            return true
        }
    }

    private var shouldShowBottomBar: Bool {
        store.step != .alarm && shouldShowNavigationBars
    }

    private var canContinue: Bool {
        switch store.step {
        case .questions:
            guard store.questionIndex < store.questions.count else {
                return false
            }

            let question = store.questions[store.questionIndex]

            guard let answer = store.answers[question.id] else {
                return false
            }

            switch answer {
            case let .multiple(values):
                return !values.isEmpty

            case .single, .time:
                return true
            }

        case .alarm:
            return store.alarm.authorizationStatus == .authorized

        case .apps:
            return store.appBlocking.errorMessage == nil

        case .tasks, .summary:
            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.sm) {
                if shouldShowNavigationBars {
                    topBar
                }

                ZStack(alignment: .top) {
                    Group {
                        switch store.step {
                        case .questions:
                            QuestionsView(
                                store: store,
                                question: store.questions[store.questionIndex]
                            )

                        case .alarm:
                            AlarmView(
                                store: store.scope(state: \.alarm, action: \.alarm),
                                isNavigationLocked: store.isNavigationLocked
                            ) {
                                OnboardingHeading(
                                    title: "Set your alarm",
                                    subtitle: ""
                                )
                            }

                        case .apps:
                            AppBlockingView(
                                store: store.scope(state: \.appBlocking, action: \.appBlocking)
                            ) {
                                OnboardingHeading(
                                    title: "Choose distracting apps",
                                    subtitle: ""
                                )
                            }

                        case .tasks:
                            TasksView()

                        case .summary:
                            OnboardingSummary(store: store)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .id(store.currentStep)
                    .transition(OnboardingPageTransition(
                        store: store,
                        page: store.currentStep,
                        reduceMotion: reduceMotion
                    ))
                }
                .disabled(store.isNavigationLocked)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .top
                )
                .animation(
                    reduceMotion ? nil : .smooth(duration: 0.3),
                    value: store.currentStep
                )
            }
            .safeAreaPadding(.horizontal, DesignSystem.Spacing.lg)
            .background(DesignSystem.Semantic.backgroundPrimary.ignoresSafeArea())
            .tint(DesignSystem.Palette.brand500)
            .onSwipeBack(isEnabled: canGoBack) {
                store.send(.backTapped)
            }
            .toolbar(.hidden, for: .navigationBar)

            .safeAreaInset(edge: .bottom, spacing: 0) {
                if shouldShowBottomBar || store.persistenceErrorMessage != nil || store.syncErrorMessage != nil {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        if let message = store.syncErrorMessage {
                            Text(message)
                                .font(.callout)
                                .foregroundStyle(DesignSystem.Palette.danger600)
                                .multilineTextAlignment(.center)
                            AppButton(action: { store.send(.retrySyncTapped) }) {
                                Text("Retry Save")
                            }
                            .disabled(store.isSyncing)
                        }
                        if let message = store.persistenceErrorMessage {
                            Text(message)
                                .font(.callout)
                                .foregroundStyle(DesignSystem.Palette.danger600)
                                .multilineTextAlignment(.center)
                        }
                        if shouldShowBottomBar {
                            bottomBar
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.lg)
                    .background(DesignSystem.Semantic.backgroundPrimary)
                }
            }
        }
//        .task {
//            store.send(.task)
//        }
    }
}

#Preview {
    OnboardingView(
        store: Store(
            initialState: OnboardingProvider.State(
                step: .questions,
                alarm: AlarmProvider.State(authorizationStatus: .authorized)
            )
        ) {
            OnboardingProvider()
        }
    )
}

#Preview("Dark • Alarm") {
    OnboardingView(store: Store(initialState: OnboardingProvider.State(
        step: .alarm,
        alarm: AlarmProvider.State(authorizationStatus: .authorized)
    )) {
        OnboardingProvider()
    })
    .preferredColorScheme(.dark)
}

#Preview("Tasks • Large text") {
    OnboardingView(store: Store(initialState: OnboardingProvider.State(step: .tasks)) {
        OnboardingProvider()
    })
    .environment(\.dynamicTypeSize, .accessibility1)
}

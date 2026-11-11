import SwiftUI
import ComposableArchitecture

struct QuestionsView: View {
    let store: StoreOf<OnboardingProvider>
    let question: Question

    private var selectedOptions: Set<String> {
        switch store.answers[question.id] {
        case let .single(selected): [selected]
        case let .multiple(selected): selected
        default: []
        }
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.XXL) {
            OnboardingHeading(
                title: question.heading,
                subtitle: question.subHeading
            )

            switch question.body {
            case let .single(options):
                OnboardingOptions(options: options, selected: selectedOptions) {
                    store.send(.singleAnswerSelected($0))
                }

            case let .multiple(options):
                OnboardingOptions(options: options, selected: selectedOptions) {
                    store.send(.multipleAnswerToggled($0))
                }

            case .time:
                ClockTimePicker(
                    selection: Binding(
                        get: { selectedTime },
                        set: { store.send(.timeAnswerSelected($0)) }
                    )
                )
                .padding(.horizontal, -DesignSystem.Spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Wake-up time")
            }
        }
        .padding(.vertical, DesignSystem.Spacing.XXL)
        .onAppear(perform: initializeTimeAnswer)
    }

    private var selectedTime: Date {
        if case let .time(date) = store.answers[question.id] {
            return date
        }
        return Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now) ?? .now
    }

    private func initializeTimeAnswer() {
        guard case .time = question.body, store.answers[question.id] == nil else { return }
        store.send(.timeAnswerSelected(selectedTime))
    }

}

#Preview {
    OnboardingView(store: Store(initialState: OnboardingProvider.State()) {
        OnboardingProvider()
    })
}

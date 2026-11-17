import ComposableArchitecture
import SwiftUI

struct QuestionsView: View {
    let store: StoreOf<OnboardingFeature>

    private var question: Question { store.question }

    private var selectedOption: String? {
        if case let .single(selected) = store.answers[question.id] { return selected }
        return nil
    }

    private var selectedTime: Date {
        if case let .time(date) = store.answers[question.id] { return date }
        guard case let .time(hour, minute) = question.body else { return .now }
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }

    var body: some View {
        switch question.body {
        case .time:
            ClockTimePicker(selection: Binding { selectedTime } set: { store.send(.timeAnswerSelected($0)) })
                .padding(.horizontal, -Spacing.lg)
                .accessibilityLabel(question.heading)
                .onAppear {
                    // Record the default time so the question can be answered without touching the clock.
                    if store.answers[question.id] == nil { store.send(.timeAnswerSelected(selectedTime)) }
                }
        case let .single(options):
            optionList(options)
        }
    }

    private func optionList(_ options: [QuestionOption]) -> some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                ForEach(options) { option in
                    OptionButton(isSelected: selectedOption == option.id, showsCheckmark: false) {
                        store.send(.singleAnswerSelected(option.id))
                    } label: {
                        Text(option.title)
                    }
                }
            }
            .padding(.vertical, Spacing.xs)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollClipDisabled() // Let the capsules' glass shadow show past the list's edge.
        .sensoryFeedback(.selection, trigger: selectedOption)
    }
}

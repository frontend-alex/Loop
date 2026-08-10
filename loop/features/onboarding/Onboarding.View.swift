//
//  Onboarding.View.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/08/2026.
//

import SwiftUI
import ComposableArchitecture

struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>
    
    private var topBar: some View {
        HStack {
            Button("Back"){
                store.send(.backTapped)
            }
            .disabled(
                store.step == .questions && store.questionIndex == 0
            )
            
            Spacer()
        }
        .padding()
    }
    
    private var bottomBar: some View {
        Button(
            store.step == .summary
                ? "Finish"
                : "Continue"
        ) {
            store.send(
                store.step == .summary
                ? .finishTapped
                : .nextTapped
            )
        }
    }

    private func isSelected(
        _ option: String,
        for question: Question
    ) -> Bool {
        switch store.draft.answers[question.id] {
        case let .single(selected):
            return selected == option
        case let .multiple(selected):
            return selected.contains(option)
        default:
            return false
        }
    }

    private var questionView: some View {
        let question = store.questions[store.questionIndex]

        return VStack(spacing: 16) {
            Text(question.heading)
                .font(.title)

            Text(question.subHeading)
                .foregroundStyle(.secondary)

            switch question.body {
            case let .single(options):
                ForEach(options, id: \.self) { option in
                    Button {
                        store.send(.singleAnswerSelected(option))
                    } label: {
                        HStack {
                            Text(option)

                            Spacer()

                            if isSelected(option, for: question) {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(
                        isSelected(option, for: question)
                            ? .accentColor
                            : .secondary
                    )
                }

            case let .multiple(options):
                ForEach(options, id: \.self) { option in
                    Button {
                        store.send(.multipleAnswerToggled(option))
                    } label: {
                        HStack {
                            Text(option)

                            Spacer()

                            if isSelected(option, for: question) {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(
                        isSelected(option, for: question)
                            ? .accentColor
                            : .secondary
                    )
                }

            case .time:
                DatePicker(
                    "Select time",
                    selection: Binding(
                        get: {
                            if case let .time(date) = store.draft.answers[question.id] {
                                return date
                            }

                            return Date()
                        },
                        set: { date in
                            store.send(.timeAnswerSelected(date))
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    var body: some View {
        VStack(spacing: 16)
        {
            topBar
            
            Spacer()
            
            switch store.step {
            case .questions:
                questionView
            case .alarm:
                AlarmView()
            case .apps:
                Text("Apps")
            case .tasks:
                Text("Tasks")
            case .summary:
                Text("Summary")
            }
            
            Spacer()
            
            bottomBar
        }
    }
}


#Preview {
    OnboardingView(
       store: Store(
         initialState: OnboardingFeature.State(step: .alarm)
       ) {
           OnboardingFeature()
       }
    )
}

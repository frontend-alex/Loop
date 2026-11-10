import SwiftUI
import ComposableArchitecture

struct OnboardingProgress: View {
    let store: StoreOf<OnboardingProvider>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let titles = ["About you", "Alarm", "Tasks"]

    private var stage: Int {
        switch store.step {
        case .questions: 0
        case .alarm, .apps: 1
        case .tasks, .summary: 2
        }
    }

    private var progress: Double {
        switch store.step {
        case .questions:
            Double(store.questionIndex) / Double(max(store.questions.count, 1))
        case .alarm, .tasks: 0
        case .apps: 0.5
        case .summary: 1
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(titles.indices, id: \.self) { index in
                GeometryReader { geometry in
                    Capsule()
                        .fill(DesignSystem.Semantic.borderDefault)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(DesignSystem.Palette.brand500)
                                .frame(width: geometry.size.width * (index < stage ? 1 : (index == stage ? progress : 0)))
                        }
                }
            }
        }
        .frame(height: 8)
        .animation(reduceMotion ? nil : DesignSystem.Motion.transition, value: Double(stage) + progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Stage \(stage + 1) of 3, \(titles[stage]), \(Int(progress * 100)) percent complete")
    }
}

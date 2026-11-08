import SwiftUI

struct OnboardingProgressStyle: ProgressViewStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let progress = configuration.fractionCompleted ?? 0

        GeometryReader { geometry in
            Capsule()
                .fill(.quaternary)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(DesignSystem.Palette.brand500)
                        .frame(width: geometry.size.width * progress)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 0.3),
                            value: progress
                        )
                }
        }
        .frame(height: DesignSystem.Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}

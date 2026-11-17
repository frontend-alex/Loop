import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The task list scrolls under the floating arrow, which tucks away until scrolling stops.
    @State private var isScrolling = false

    /// The app step shows its own permission screen, without navigation bars, until access is granted.
    private var showsBars: Bool {
        store.step != .apps || store.appBlocking.authorizationStatus == .authorized
    }

    /// The app picker fills the screen down to its own search field, so its arrow sits in the top bar.
    private var showsArrowInTopBar: Bool { store.step == .apps }

    private var morph: Animation? { reduceMotion ? nil : .smooth(duration: 0.4) }

    private var canGoBack: Bool {
        showsBars && !store.isCompleted && !store.alarm.isSaving && store.currentStep > 0
    }

    private var canContinue: Bool {
        switch store.step {
        case .questions:
            store.answers[store.question.id] != nil
        case .alarm: store.alarm.authorizationStatus != .requesting
        case .apps: store.appBlocking.errorMessage == nil
        case .tasks: !store.selectedTaskIDs.isEmpty
        case .summary: true
        }
    }

    private var isBusy: Bool {
        store.alarm.isSaving || store.alarm.authorizationStatus == .requesting
    }

    private var continueTitle: String {
        switch store.step {
        case .alarm: "Set Alarm"
        case .summary: "Finish"
        default: "Continue"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.sm) {
                if showsBars {
                    HStack(spacing: Spacing.lg) {
                        Button("Back", systemImage: "chevron.left") { store.send(.backTapped, animation: morph) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.app(.secondary, size: .icon))
                            .disabled(!canGoBack)

                        ProgressBar(value: Double(store.currentStep) / Double(OnboardingFeature.State.stepCount))

                        if showsArrowInTopBar {
                            continueButton(size: .icon)
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }

                ZStack(alignment: .top) {
                    page
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .id(store.currentStep)
                        .transition(OnboardingPageTransition(store: store, page: store.currentStep, reduceMotion: reduceMotion))
                }
                .disabled(store.isCompleted)
                .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: store.currentStep)
            }
            .safeAreaPadding(.horizontal, Spacing.lg)
            .background(.backgroundPrimary)
            .tint(.brand)
            .onSwipeBack(isEnabled: canGoBack) { store.send(.backTapped) }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        }
    }

    /// Every step's heading, drawn in one place so it has the same size and position throughout.
    private var heading: (title: String, subtitle: String)? {
        switch store.step {
        case .questions: (store.question.heading, store.question.subHeading)
        case .alarm: ("Set your alarm", "")
        case .apps: showsBars ? ("Choose distracting apps", "") : nil // The permission screen has its own.
        case .tasks: ("Wake-up Tasks", "You'll get one each morning.")
        case .summary: ("You're set", "")
        }
    }

    /// Steps that show the clock dials; their headings are centered and sized alike.
    private var isDialStep: Bool {
        switch store.step {
        case .questions: if case .time = store.question.body { true } else { false }
        case .alarm, .summary: true
        case .apps, .tasks: false
        }
    }

    private var page: some View {
        VStack(spacing: Spacing.lg) {
            if let heading {
                OnboardingHeading(title: heading.title, subtitle: heading.subtitle, isForDial: isDialStep)
            }
            pageContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(-1) // Dial circles and scrolled rows pass behind the heading.
        }
        .padding(.top, showsBars ? Spacing.lg : 0)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch store.step {
        case .questions:
            QuestionsView(store: store)
        case .alarm:
            AlarmView(store: store.scope(state: \.alarm, action: \.alarm))
        case .apps:
            AppBlockingView(store: store.scope(state: \.appBlocking, action: \.appBlocking))
        case .tasks:
            TasksView(store: store, isScrolling: $isScrolling)
        case .summary:
            OnboardingSummary(store: store)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        let showsArrow = showsBars && !showsArrowInTopBar
        let isSummary = store.step == .summary
        if showsArrow || store.persistenceErrorMessage != nil {
            VStack(spacing: Spacing.sm) {
                if let message = store.persistenceErrorMessage {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.danger)
                        .multilineTextAlignment(.center)
                }
                if showsArrow {
                    HStack(alignment: .center) {
                        if store.step == .alarm {
                            AlarmPreferences(store: store.scope(state: \.alarm, action: \.alarm))
                                .disabled(isBusy)
                        }
                        if isSummary {
                            SummaryShortcuts(store: store)
                                .transition(.opacity)
                        }
                        if !isSummary {
                            Spacer(minLength: 0)
                        }
                        let isTucked = isScrolling && store.step == .tasks
                        morphingContinueButton(isExpanded: isSummary)
                            .scaleEffect(isTucked ? 0.3 : 1)
                            .blur(radius: isTucked ? 8 : 0)
                            .opacity(isTucked ? 0 : 1)
                            .allowsHitTesting(!isTucked)
                            .animation(reduceMotion ? .default : .smooth(duration: 0.3), value: isTucked)
                    }
                }
            }
            .padding(Spacing.lg)
        }
    }

    /// The round arrow that stretches into the full-width Finish on the summary step (and back).
    private func morphingContinueButton(isExpanded: Bool) -> some View {
        Button {
            store.send(isExpanded ? .finishTapped : .nextTapped, animation: morph)
        } label: {
            ZStack {
                if isExpanded {
                    Text("Finish")
                } else if isBusy {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                }
            }
            .transition(.opacity)
        }
        .buttonStyle(MorphingButtonStyle(isExpanded: isExpanded))
        .accessibilityLabel(continueTitle)
        .disabled(!canContinue || isBusy || store.isCompleted)
    }

    private func continueButton(size: AppButtonStyle.Size) -> some View {
        Button {
            // Animated so the round arrow visibly stretches into Finish (and back).
            store.send(.nextTapped, animation: morph)
        } label: {
            if isBusy {
                ProgressView()
            } else {
                Label(continueTitle, systemImage: "chevron.right").labelStyle(.iconOnly)
            }
        }
        .buttonStyle(.app(size: size))
        .accessibilityLabel(continueTitle)
        .disabled(!canContinue || isBusy || store.isCompleted)
    }
}

/// A solid capsule rather than Liquid Glass: glass is rebuilt instead of resized when its
/// width changes this much, so it can't animate from a circle to full width.
private struct MorphingButtonStyle: ButtonStyle {
    let isExpanded: Bool

    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration, isExpanded: isExpanded)
    }

    private struct StyledLabel: View {
        let configuration: Configuration
        let isExpanded: Bool

        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color(isEnabled ? "LoopSemantic-Button-Primary-Foreground" : "LoopSemantic-Button-Disabled-Foreground"))
                .frame(minWidth: 56, maxWidth: isExpanded ? .infinity : 56, minHeight: 56)
                .clipShape(.capsule) // Keep the cross-fading label inside the shape while it stretches.
                .background(Color(isEnabled ? "LoopSemantic-Button-Primary-Tint" : "LoopSemantic-Button-Disabled-Tint"), in: .capsule)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                .contentShape(.capsule)
                .scaleEffect(configuration.isPressed ? 0.96 : 1)
                .animation(.snappy(duration: 0.15), value: configuration.isPressed)
        }
    }
}

private struct ProgressBar: View {
    let value: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Capsule()
            .fill(.border)
            .overlay(alignment: .leading) {
                GeometryReader { geometry in
                    Capsule().fill(.brand).frame(width: geometry.size.width * value)
                }
            }
            .frame(height: 2)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: value)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Onboarding progress")
            .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
    }
}

/// Slides pages in the direction of travel. A page that is leaving reads the store to learn
/// where the flow is going, so going back never reuses the page's old forward direction.
struct OnboardingPageTransition: Transition {
    let store: StoreOf<OnboardingFeature>
    let page: Int
    let reduceMotion: Bool

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .offset(x: horizontalOffset(for: phase))
            .opacity(phase.isIdentity ? 1 : 0)
    }

    func horizontalOffset(for phase: TransitionPhase) -> CGFloat {
        guard !phase.isIdentity, !reduceMotion else { return 0 }
        let movesRight = phase == .willAppear ? !store.isNavigatingBack : store.currentStep < page
        return movesRight ? Spacing.lg : -Spacing.lg
    }
}

#Preview {
    OnboardingView(store: Store(initialState: OnboardingFeature.State()) { OnboardingFeature() })
}

#Preview("Dark • Alarm") {
    OnboardingView(store: Store(initialState: OnboardingFeature.State(
        step: .alarm,
        alarm: AlarmFeature.State(authorizationStatus: .authorized)
    )) { OnboardingFeature() })
    .preferredColorScheme(.dark)
}

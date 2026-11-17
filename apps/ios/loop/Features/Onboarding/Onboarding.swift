import Foundation

nonisolated enum OnboardingStep: String, Codable, Sendable {
    case questions
    case alarm
    case apps
    case tasks
    case summary
}

nonisolated struct OnboardingDraft: Equatable, Codable, Sendable {
    var step: OnboardingStep = .questions
    var questionIndex = 0
    var answers: [String: QuestionAnswer] = [:]
    var alarm: Alarm?
    var distractingApps: [AppSelection] = []
    var taskIDs: Set<String> = []
}

nonisolated struct OnboardingRequest: Codable, Equatable, Sendable {
    let answers: [String: QuestionAnswer]
    let currentStep: Int
}

/// An answer choice. The ID is what gets stored and sent, so the wording can change freely.
nonisolated struct QuestionOption: Identifiable, Equatable, Codable, Sendable {
    let id: String
    let title: String
}

nonisolated enum QuestionBody: Equatable, Codable, Sendable {
    case single(options: [QuestionOption])
    /// A clock time, starting at the given hour and minute until the user answers.
    case time(hour: Int, minute: Int)
}

/// The onboarding questionnaire. Wording follows validated sleep research where it exists
/// (MCTQ for sleep timing); see docs/onboarding-questions.md. Kept to five so it stays quick.
nonisolated struct Question: Identifiable, Equatable, Codable, Sendable {
    let id: String
    let heading: String
    let subHeading: String
    let body: QuestionBody

    /// The workday wake-up time, which also becomes the alarm's starting time.
    static let wakeTimeID = "workday-wake-time"

    static let all: [Question] = [
        Question(
            id: "morning-goal",
            heading: "What do you want from your mornings?",
            subHeading: "Choose the one that matters most.",
            body: .single(options: [
                QuestionOption(id: "get-up-on-time", title: "Get up on time"),
                QuestionOption(id: "stop-scrolling", title: "Stop scrolling first thing"),
                QuestionOption(id: "build-routine", title: "Build a routine"),
                QuestionOption(id: "feel-awake", title: "Feel more awake")
            ])
        ),
        Question(
            id: wakeTimeID,
            heading: "When do you need to be up on workdays?",
            subHeading: "",
            body: .time(hour: 7, minute: 0)
        ),
        Question(
            id: "waking-style",
            heading: "How do you wake up now?",
            subHeading: "",
            body: .single(options: [
                QuestionOption(id: "first-alarm", title: "With the first alarm"),
                QuestionOption(id: "snooze-1-2", title: "Snooze once or twice"),
                QuestionOption(id: "snooze-3-plus", title: "Snooze three times or more"),
                QuestionOption(id: "several-alarms", title: "I set several alarms")
            ])
        ),
        Question(
            id: "first-phone-use",
            heading: "When do you first pick up your phone?",
            subHeading: "After waking up.",
            body: .single(options: [
                QuestionOption(id: "in-bed", title: "Before I'm out of bed"),
                QuestionOption(id: "within-10-min", title: "Within 10 minutes"),
                QuestionOption(id: "within-30-min", title: "Within 30 minutes"),
                QuestionOption(id: "later", title: "Later than that")
            ])
        ),
        Question(
            id: "morning-time-available",
            heading: "How much time do you have in the morning?",
            subHeading: "Before you need to leave or start your day.",
            body: .single(options: [
                QuestionOption(id: "under-15-min", title: "Under 15 minutes"),
                QuestionOption(id: "15-30-min", title: "15 to 30 minutes"),
                QuestionOption(id: "30-60-min", title: "30 to 60 minutes"),
                QuestionOption(id: "over-60-min", title: "Over an hour")
            ])
        )
    ]
}

nonisolated enum QuestionAnswer: Equatable, Codable, Sendable {
    case single(String)
    case time(Date)
}

/// A morning challenge the user can be given. Placeholder list until the backend provides it.
nonisolated struct WakeUpTask: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let detail: String
    /// Asset name of the task's figure.
    let icon: String

    static let all: [WakeUpTask] = [
        WakeUpTask(id: "stretch", title: "Timed Stretch", detail: "2 min", icon: "TaskStretch"),
        WakeUpTask(id: "walk", title: "Walk", detail: "300 steps", icon: "TaskWalk"),
        WakeUpTask(id: "get-up", title: "Get Up", detail: "Stand, then confirm", icon: "TaskGetUp"),
        WakeUpTask(id: "mental", title: "Mental Start", detail: "5 puzzles", icon: "TaskMental"),
        WakeUpTask(id: "body", title: "Body Start", detail: "20 squats", icon: "TaskBody"),
        WakeUpTask(id: "mobility", title: "Morning Mobility", detail: "5 moves", icon: "TaskMobility"),
        WakeUpTask(id: "brain-body", title: "Brain and Body", detail: "Puzzle, then 15 squats", icon: "TaskBrainBody")
    ]
}

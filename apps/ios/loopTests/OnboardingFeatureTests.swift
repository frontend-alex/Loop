import ComposableArchitecture
import FamilyControls
import Foundation
import Testing
@testable import loop

/// Navigation and local persistence. Every store starts offline, so nothing is uploaded.
@MainActor
struct OnboardingFeatureTests {
    private let defaults: UserDefaults
    private let clock = TestClock()

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "loop.onboarding.tests.\(UUID())"))
    }

    private func makeStore(_ state: OnboardingFeature.State) -> TestStoreOf<OnboardingFeature> {
        TestStore(initialState: state) {
            OnboardingFeature()
        } withDependencies: {
            $0.defaultAppStorage = defaults
            $0.continuousClock = clock
        }
    }

    @Test func backThenContinueReversesTheTransitionDirection() async {
        let store = makeStore(OnboardingFeature.State(questionIndex: 1, isConnected: false))

        await store.send(.backTapped) {
            $0.questionIndex = 0
            $0.isNavigatingBack = true
        }
        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.isNavigatingBack = false
            $0.pendingSync = .update
        }
    }

    @Test func backAtTheFirstQuestionDoesNothing() async {
        let store = makeStore(OnboardingFeature.State())
        await store.send(.backTapped)
    }

    @Test(arguments: [
        OnboardingFeature.Action.alarm(.delegate(.saved)),
        .appBlocking(.delegate(.skipped))
    ])
    func featureCompletionAlwaysMovesForward(action: OnboardingFeature.Action) async {
        let isAppBlocking: Bool
        if case .appBlocking = action { isAppBlocking = true } else { isAppBlocking = false }
        let store = makeStore(OnboardingFeature.State(
            step: isAppBlocking ? .apps : .alarm,
            isNavigatingBack: true,
            isConnected: false
        ))

        await store.send(action) {
            $0.step = isAppBlocking ? .tasks : .apps
            $0.isNavigatingBack = false
            $0.pendingSync = .update
        }
    }

    @Test func alarmStepAdvancesOnlyAfterTheFeatureSaves() async {
        let id = UUID()
        let store = makeStore(OnboardingFeature.State(
            step: .alarm,
            alarm: AlarmFeature.State(authorizationStatus: .authorized, isSaving: true),
            isConnected: false
        ))

        await store.send(.alarm(.saveSucceeded(id))) {
            $0.alarm.isSaving = false
            $0.alarm.alarm.scheduledID = id
        }
        await store.receive(.alarm(.delegate(.saved))) {
            $0.step = .apps
            $0.pendingSync = .update
        }
        #expect(store.state.draft.alarm?.scheduledID == id)

        await store.send(.backTapped) {
            $0.isNavigatingBack = true
            $0.step = .alarm
        }
        #expect(store.state.alarm.alarm.scheduledID == id)
    }

    @Test func navigationWaitsForAnInFlightSave() async {
        let store = makeStore(OnboardingFeature.State(step: .alarm, alarm: AlarmFeature.State(isSaving: true)))

        await store.send(.backTapped)
        await store.send(.nextTapped)
    }

    @Test func appSelectionSurvivesStepNavigationAndBuildsTheDraft() async {
        let selection = AppSelection(encodedSelection: Data("saved-selection".utf8))
        let store = makeStore(OnboardingFeature.State(
            step: .apps,
            appBlocking: AppBlockingFeature.State(authorizationStatus: .authorized, savedSelection: selection),
            isConnected: false
        ))

        await store.send(.nextTapped) {
            $0.step = .tasks
            $0.pendingSync = .update
        }
        await store.send(.backTapped) {
            $0.isNavigatingBack = true
            $0.step = .apps
        }
        #expect(store.state.draft.distractingApps == [selection])
    }

    @Test func featureSkipDelegatesControlTheFlow() async {
        let store = makeStore(OnboardingFeature.State(step: .apps, isConnected: false))

        await store.send(.appBlocking(.permissionSkipped))
        await store.receive(.appBlocking(.delegate(.skipped))) {
            $0.step = .tasks
            $0.pendingSync = .update
        }
        await store.send(.nextTapped) // No task picked yet.
        await store.send(.taskToggled("walk")) { $0.selectedTaskIDs = ["walk"] }
        await store.send(.nextTapped) {
            $0.step = .summary
        }
        await store.send(.finishTapped) {
            $0.pendingSync = .complete
            $0.isCompleted = true
        }
        await store.receive(.delegate(.completed))
        #expect(defaults.data(forKey: OnboardingFeature.draftKey) != nil)
        #expect(OnboardingFeature.State.restored(from: defaults).isCompleted)
    }

    @Test func answersAndNavigationAreSavedImmediately() async throws {
        let store = makeStore(OnboardingFeature.State(isConnected: false))

        await store.send(.singleAnswerSelected("build-routine")) {
            $0.answers["morning-goal"] = .single("build-routine")
        }
        #expect(store.state.pendingSync == nil, "Answering alone does not upload")
        let answerData = try #require(defaults.data(forKey: OnboardingFeature.draftKey))
        #expect(try JSONDecoder().decode(OnboardingDraft.self, from: answerData) == store.state.draft)

        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.pendingSync = .update
        }
        await store.send(.timeAnswerSelected(Date(timeIntervalSince1970: 0))) {
            $0.answers["workday-wake-time"] = .time(Date(timeIntervalSince1970: 0))
        }
        let restored = OnboardingFeature.State.restored(from: defaults)
        #expect(restored.questionIndex == 1)
        #expect(restored.answers["morning-goal"] == .single("build-routine"))
    }

    @Test func pickingASingleAnswerStaysOnTheQuestion() async {
        let store = makeStore(OnboardingFeature.State(isConnected: false))

        await store.send(.singleAnswerSelected("get-up-on-time")) { $0.answers["morning-goal"] = .single("get-up-on-time") }
        await store.send(.singleAnswerSelected("build-routine")) { $0.answers["morning-goal"] = .single("build-routine") }
        await clock.run()
        #expect(store.state.questionIndex == 0)
    }

    @Test func theAlarmStartsAtTheWorkdayWakeUpTime() async {
        let wakeUp = Date(timeIntervalSince1970: 1_800_000_000)
        var state = OnboardingFeature.State(questionIndex: Question.all.count - 1, isConnected: false)
        state.answers[Question.wakeTimeID] = .time(wakeUp)
        let store = makeStore(state)

        await store.send(.nextTapped) {
            $0.step = .alarm
            $0.alarm.alarm.time = wakeUp
            $0.alarm.hasInitializedTime = true
            $0.pendingSync = .update
        }
    }

    @Test func summaryRowsJumpBackToTheirStep() async {
        let store = makeStore(OnboardingFeature.State(step: .summary, isConnected: false))

        await store.send(.editTapped(.apps)) {
            $0.step = .apps
            $0.isNavigatingBack = true
        }
        await store.send(.editTapped(.apps))
    }

    @Test func tasksToggleAndSurviveARelaunch() async {
        let store = makeStore(OnboardingFeature.State(step: .tasks, isConnected: false))

        await store.send(.taskToggled("walk")) { $0.selectedTaskIDs = ["walk"] }
        await store.send(.taskToggled("mental")) { $0.selectedTaskIDs = ["walk", "mental"] }
        await store.send(.taskToggled("walk")) { $0.selectedTaskIDs = ["mental"] }
        #expect(OnboardingFeature.State.restored(from: defaults).selectedTaskIDs == ["mental"])
    }

    @Test func reopeningRestoresFeatureDraftsWithoutRestoringTransientState() throws {
        let selection = FamilyActivitySelection(includeEntireCategory: true)
        var original = OnboardingFeature.State(step: .apps)
        original.questionIndex = 3
        original.answers["morning-goal"] = .single("build-routine")
        original.answers["workday-wake-time"] = .time(Date(timeIntervalSince1970: 1_800_000_000))
        original.selectedTaskIDs = ["walk", "mental"]
        original.alarm.alarm.scheduledID = UUID()
        original.alarm.alarm.label = "Morning"
        original.alarm.isSaving = true
        original.appBlocking.savedSelection = AppSelection(encodedSelection: try JSONEncoder().encode(selection))
        original.appBlocking.authorizationStatus = .requesting
        defaults.set(try JSONEncoder().encode(original.draft), forKey: OnboardingFeature.draftKey)

        let restored = OnboardingFeature.State.restored(from: defaults)
        #expect(restored.draft == original.draft)
        #expect(restored.appBlocking.selection == selection)
        #expect(restored.alarm.isSaving == false)
        #expect(restored.appBlocking.authorizationStatus != .requesting)
    }

    @Test func childFeatureChangesUpdateTheSavedDraft() async throws {
        let id = UUID()
        let store = makeStore(OnboardingFeature.State(step: .alarm, isConnected: false))

        await store.send(.alarm(.saveSucceeded(id))) {
            $0.alarm.alarm.scheduledID = id
        }
        await store.receive(.alarm(.delegate(.saved))) {
            $0.step = .apps
            $0.pendingSync = .update
        }
        store.exhaustivity = .off
        await store.send(.appBlocking(.selectionChanged(FamilyActivitySelection())))

        let restored = OnboardingFeature.State.restored(from: defaults)
        #expect(restored.step == .apps)
        #expect(restored.alarm.alarm.scheduledID == id)
        #expect(restored.draft.distractingApps == store.state.draft.distractingApps)
        #expect(!restored.draft.distractingApps.isEmpty)
    }

    @Test func invalidDraftStartsFreshWithoutCrashing() {
        defaults.set(Data("invalid-json".utf8), forKey: OnboardingFeature.draftKey)
        let restored = OnboardingFeature.State.restored(from: defaults)

        #expect(restored.step == .questions)
        #expect(restored.questionIndex == 0)
        #expect(restored.answers.isEmpty)
        #expect(restored.persistenceErrorMessage != nil)
    }

    @Test(arguments: [-20, 999])
    func restoredQuestionIndexIsClamped(index: Int) throws {
        defaults.set(try JSONEncoder().encode(OnboardingDraft(questionIndex: index)), forKey: OnboardingFeature.draftKey)

        let restored = OnboardingFeature.State.restored(from: defaults)
        #expect(Question.all.indices.contains(restored.questionIndex))
    }
}

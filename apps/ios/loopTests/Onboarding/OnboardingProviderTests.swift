import ComposableArchitecture
import FamilyControls
import Foundation
import Testing
@testable import loop

@MainActor
struct OnboardingProviderTests {
    private let defaults: UserDefaults
    private let fixture: (session: URLSession, baseURL: URL)

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "loop.onboarding.tests.\(UUID())"))
        fixture = try OnboardingURLProtocol.fixture()
    }

    @Test func alarmStepAdvancesOnlyAfterTheFeatureSaves() async {
        let id = UUID()
        let store = TestStore(initialState: OnboardingProvider.State(
            step: .alarm,
            alarm: AlarmProvider.State(authorizationStatus: .authorized, isSaving: true)
        )) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "test-token" }
        }

        await store.send(.alarm(.saveSucceeded(id))) {
            $0.alarm.isSaving = false
            $0.alarm.alarm.scheduledID = id
        }
        await store.receive(.alarm(.delegate(.saved))) {
            $0.step = .apps
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }
        #expect(store.state.draft.alarm?.scheduledID == id)

        await store.send(.backTapped) {
            $0.isNavigatingBack = true
            $0.step = .alarm
        }
        #expect(store.state.alarm.alarm.scheduledID == id)
    }

    @Test func navigationWaitsForAnInFlightSave() async {
        let store = TestStore(initialState: OnboardingProvider.State(
            step: .alarm,
            alarm: AlarmProvider.State(isSaving: true)
        )) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        }

        await store.send(.backTapped)
        await store.send(.nextTapped)
        #expect(store.state.step == .alarm)
    }

    @Test func appSelectionSurvivesStepNavigationAndBuildsTheDraft() async {
        let selection = AppSelection(encodedSelection: Data("saved-selection".utf8))
        let store = TestStore(initialState: OnboardingProvider.State(
            step: .apps,
            appBlocking: AppBlockingProvider.State(
                authorizationStatus: .authorized,
                savedSelection: selection
            )
        )) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "test-token" }
        }

        await store.send(.nextTapped) {
            $0.step = .tasks
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }
        await store.send(.backTapped) {
            $0.isNavigatingBack = true
            $0.step = .apps
        }
        #expect(store.state.draft.distractingApps == [selection])
    }

    @Test func featureSkipDelegatesControlTheFlow() async {
        let store = TestStore(initialState: OnboardingProvider.State(step: .alarm)) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "test-token" }
        }

        await store.send(.alarm(.permissionSkipped))
        await store.receive(.alarm(.delegate(.skipped))) {
            $0.step = .apps
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }
        await store.send(.appBlocking(.permissionSkipped))
        await store.receive(.appBlocking(.delegate(.skipped))) {
            $0.step = .tasks
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }
        await store.send(.nextTapped) {
            $0.step = .summary
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }
        await store.send(.finishTapped) {
            $0.isSyncing = true
            $0.pendingSync = .complete
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
            $0.isCompleted = true
        }
        await store.receive(.delegate(.completed))
        #expect(defaults.data(forKey: OnboardingProvider.draftKey) == nil)
        #expect(OnboardingProvider.State.restored(from: defaults).isCompleted)
    }

    @Test func answersAndNavigationAreSavedImmediately() async throws {
        let store = TestStore(initialState: OnboardingProvider.State()) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "test-token" }
        }

        await store.send(.singleAnswerSelected("High")) {
            $0.answers["focus"] = .single("High")
        }
        let answerData = try #require(defaults.data(forKey: OnboardingProvider.draftKey))
        #expect(try JSONDecoder().decode(OnboardingDraft.self, from: answerData) == store.state.draft)

        await store.send(.nextTapped) {
            $0.questionIndex = 1
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }
        let restored = OnboardingProvider.State.restored(from: defaults)
        #expect(restored.questionIndex == 1)
        #expect(restored.answers["focus"] == .single("High"))
    }

    @Test func reopeningRestoresFeatureDraftsWithoutRestoringTransientState() throws {
        let selection = FamilyActivitySelection(includeEntireCategory: true)
        let appSelection = AppSelection(encodedSelection: try JSONEncoder().encode(selection))
        var original = OnboardingProvider.State(step: .apps)
        original.questionIndex = 3
        original.answers["focus"] = .single("High")
        original.answers["distractions"] = .multiple(["Games", "Messages"])
        original.answers["wake-time"] = .time(Date(timeIntervalSince1970: 1_800_000_000))
        original.tasks = [TaskItem(id: UUID(), title: "Read", dueDate: nil)]
        original.alarm.alarm.scheduledID = UUID()
        original.alarm.alarm.label = "Morning"
        original.alarm.isSaving = true
        original.alarm.authorizationStatus = .requesting
        original.appBlocking.savedSelection = appSelection
        original.appBlocking.isSaving = true
        original.appBlocking.authorizationStatus = .requesting
        defaults.set(try JSONEncoder().encode(original.draft), forKey: OnboardingProvider.draftKey)

        let restored = OnboardingProvider.State.restored(from: defaults)
        #expect(restored.draft == original.draft)
        #expect(restored.appBlocking.selection == selection)
        #expect(restored.alarm.isSaving == false)
        #expect(restored.appBlocking.isSaving == false)
        #expect(restored.alarm.authorizationStatus != .requesting)
        #expect(restored.appBlocking.authorizationStatus != .requesting)
    }

    @Test func childFeatureChangesUpdateTheSavedDraft() async throws {
        let id = UUID()
        let store = TestStore(initialState: OnboardingProvider.State(step: .alarm)) {
            OnboardingProvider(defaults: defaults, session: fixture.session, apiBaseURL: fixture.baseURL)
        } withDependencies: {
            $0.authTokenStore.load = { "test-token" }
        }

        await store.send(.alarm(.saveSucceeded(id))) {
            $0.alarm.alarm.scheduledID = id
        }
        await store.receive(.alarm(.delegate(.saved))) {
            $0.step = .apps
            $0.isSyncing = true
            $0.pendingSync = .update
        }
        await store.receive(.syncSucceeded) {
            $0.isSyncing = false
            $0.pendingSync = nil
        }
        let selection = AppSelection(encodedSelection: try JSONEncoder().encode(FamilyActivitySelection()))
        await store.send(.appBlocking(.selectionSaved(selection))) {
            $0.appBlocking.savedSelection = selection
        }

        let restored = OnboardingProvider.State.restored(from: defaults)
        #expect(restored.step == .apps)
        #expect(restored.alarm.alarm.scheduledID == id)
        #expect(restored.draft.distractingApps == [selection])
    }

    @Test func invalidDraftStartsFreshWithoutCrashing() {
        defaults.set(Data("invalid-json".utf8), forKey: OnboardingProvider.draftKey)
        let restored = OnboardingProvider.State.restored(from: defaults)

        #expect(restored.step == .questions)
        #expect(restored.questionIndex == 0)
        #expect(restored.answers.isEmpty)
        #expect(restored.persistenceErrorMessage != nil)
    }

    @Test(arguments: [-20, 999])
    func restoredQuestionIndexIsClamped(index: Int) throws {
        let draft = OnboardingDraft(questionIndex: index)
        defaults.set(try JSONEncoder().encode(draft), forKey: OnboardingProvider.draftKey)

        let restored = OnboardingProvider.State.restored(from: defaults)
        #expect(restored.questions.indices.contains(restored.questionIndex))
    }
}

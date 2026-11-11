import ComposableArchitecture
import FamilyControls
import Foundation
import Testing
@testable import loop

@MainActor
struct AppBlockingProviderTests {
    @Test func permissionDenialCanBeSkipped() async {
        let store = TestStore(initialState: AppBlockingProvider.State(authorizationStatus: .requesting)) {
            AppBlockingProvider()
        }

        await store.send(.authorizationSucceeded(false)) {
            $0.authorizationStatus = .denied
        }
        await store.send(.permissionSkipped)
        await store.receive(.delegate(.skipped))
    }

    @Test func selectionEncodingAndPersistenceBelongToTheFeature() async throws {
        let selection = FamilyActivitySelection(includeEntireCategory: true)
        let defaults = UserDefaults.standard
        let key = "app-blocking.selection"
        let previous = defaults.data(forKey: key)
        defer { defaults.set(previous, forKey: key) }

        let store = TestStore(initialState: AppBlockingProvider.State(authorizationStatus: .authorized)) {
            AppBlockingProvider()
        }

        await store.send(.selectionChanged(selection)) {
            $0.selection = selection
            $0.isSaving = true
        }
        await store.receive(\.selectionSaved) {
            $0.savedSelection = defaults.data(forKey: key).map(AppSelection.init(encodedSelection:))
            $0.isSaving = false
        }

        let saved = try #require(store.state.savedSelection)
        let restored = try JSONDecoder().decode(FamilyActivitySelection.self, from: saved.encodedSelection)
        #expect(restored == selection)
    }

    @Test func persistenceFailureDoesNotReplaceTheSavedSelection() async {
        let previous = AppSelection(encodedSelection: Data("previous".utf8))
        let store = TestStore(initialState: AppBlockingProvider.State(savedSelection: previous, isSaving: true)) {
            AppBlockingProvider()
        }

        await store.send(.selectionSaveFailed("Could not save")) {
            $0.isSaving = false
            $0.errorMessage = "Could not save"
        }
        #expect(store.state.savedSelection == previous)
    }
}

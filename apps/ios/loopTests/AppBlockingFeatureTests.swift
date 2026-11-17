import ComposableArchitecture
import FamilyControls
import Foundation
import Testing
@testable import loop

@MainActor
struct AppBlockingFeatureTests {
    @Test func permissionDenialCanBeSkipped() async {
        let store = TestStore(initialState: AppBlockingFeature.State(authorizationStatus: .requesting)) {
            AppBlockingFeature()
        }

        await store.send(.authorizationSucceeded(false)) {
            $0.authorizationStatus = .denied
        }
        await store.send(.permissionSkipped)
        await store.receive(.delegate(.skipped))
    }

    @Test func unknownStatusRequestsAuthorizationOnAppear() async {
        let store = TestStore(initialState: AppBlockingFeature.State()) {
            AppBlockingFeature()
        } withDependencies: {
            $0[AppBlockingClient.self].requestAuthorization = { true }
        }

        await store.send(.task)
        await store.receive(.authorizationRequested) { $0.authorizationStatus = .requesting }
        await store.receive(.authorizationSucceeded(true)) { $0.authorizationStatus = .authorized }
    }

    @Test func selectionIsEncodedForTheDraftAndRestored() async throws {
        let selection = FamilyActivitySelection(includeEntireCategory: true)
        let store = TestStore(initialState: AppBlockingFeature.State(authorizationStatus: .authorized)) {
            AppBlockingFeature()
        }

        store.exhaustivity = .off
        await store.send(.selectionChanged(selection))
        #expect(store.state.selection == selection)

        let restored = AppBlockingFeature.State.restored(from: store.state.savedSelection)
        #expect(restored.selection == selection)
        #expect(restored.errorMessage == nil)
    }

    @Test func corruptSelectionIsDroppedWithAnError() {
        let restored = AppBlockingFeature.State.restored(from: AppSelection(encodedSelection: Data("bad".utf8)))
        #expect(restored.savedSelection == nil)
        #expect(restored.errorMessage != nil)
    }
}

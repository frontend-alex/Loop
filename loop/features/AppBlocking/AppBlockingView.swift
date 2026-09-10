//
//  AppBlockingView.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/09/2026.
//
import SwiftUI
import FamilyControls
import ComposableArchitecture

#if targetEnvironment(simulator)
private let appBlockingService: AppBlockingPort = AppBlockingService()
#else
private let appBlockingService: AppBlockingPort = AppBlockingService()
#endif

struct AppBlockingView: View {
    let store: StoreOf<OnboardingProvider>
    private let restorationError: String?

    @State private var selection: FamilyActivitySelection
    @State private var isPickerPresented = false

    init(store: StoreOf<OnboardingProvider>) {
        self.store = store

        do {
            if let saved = store.draft.distractingApps.first {
                let restored = try JSONDecoder().decode(
                    FamilyActivitySelection.self,
                    from: saved.encodedSelection
                )
                _selection = State(initialValue: restored)
            } else {
                _selection = State(initialValue: FamilyActivitySelection())
            }
            restorationError = nil
        } catch {
            _selection = State(initialValue: FamilyActivitySelection())
            restorationError = "Could not restore selected apps: \(error.localizedDescription)"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose distracting apps")
                .font(.title2.bold())

            Text("Select the apps you want Loop to restrict during a focus session.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            switch store.appsAuthorizationStatus {
                
            case .unknown, .requesting:
                ProgressView("Requesting permission...")

            case .authorized:
                Button("Choose Apps") {
                    isPickerPresented = true
                }

                VStack(spacing: 4) {
                    Text("Selected apps: \(selection.applicationTokens.count)")
                    Text("Selected categories: \(selection.categoryTokens.count)")
                    Text("Selected websites: \(selection.webDomainTokens.count)")
                }
                .foregroundStyle(.secondary)

                if let message = store.appsErrorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if store.isSavingApps {
                    ProgressView("Saving selection...")
                }

            case .denied:
                Text(store.appsErrorMessage ?? "Family Controls permission is required.")
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    Task {
                        await requestAuthorization()
                    }
                }
            }
        }
        .padding()
        .task {
            await requestAuthorization()
            if let restorationError {
                store.send(.appsSelectionSaveFailed(restorationError))
            }
        }
        .onChange(of: store.appsAuthorizationStatus) { _, status in
            if status == .authorized {
                isPickerPresented = true
            }
        }
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $selection
        )
        .onChange(of: selection) { _, newSelection in
            do {
                let data = try JSONEncoder().encode(newSelection)
                let appSelection = AppSelection(encodedSelection: data)
                store.send(.appsSelectionChanged(appSelection))
                try appBlockingService.saveSelection(appSelection)
            } catch {
                store.send(.appsSelectionSaveFailed(error.localizedDescription))
            }
        }
    }

    private func requestAuthorization() async {
        store.send(.appsAuthorizationRequested)
        do {
            let authorized = try await appBlockingService.requestAuthorization()
            store.send(.appsAuthorizationSucceeded(authorized))
        } catch {
            store.send(.appsAuthorizationFailed(error.localizedDescription))
        }
    }
}

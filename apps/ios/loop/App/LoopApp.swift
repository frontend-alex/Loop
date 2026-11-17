import ComposableArchitecture
import SwiftUI

@main
struct LoopApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppFeature.State()) { AppFeature() })
        }
    }
}

struct AppView: View {
    let store: StoreOf<AppFeature>

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch store.route {
            case .splash:
                SplashView { store.send(.splashFinished) }
            case .auth:
                LandingView(store: store.scope(state: \.auth, action: \.auth))
            case .loadingUser:
                loadingUser
            case .onboarding:
                OnboardingView(store: store.scope(state: \.onboarding, action: \.onboarding))
            case .home:
                HomeView(store: store.scope(state: \.auth, action: \.auth), user: store.user)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Retry pending onboarding uploads whenever the app comes back.
            if phase == .active { store.send(.onboarding(.syncPending)) }
        }
    }

    private var loadingUser: some View {
        VStack(spacing: Spacing.md) {
            if let message = store.userError {
                Text(message)
                Button("Retry") { store.send(.retryUserFetch) }
                    .buttonStyle(.app)
                Button("Clear token and sign in again") { store.send(.auth(.logout)) }
                    .buttonStyle(.app(.secondary))
                if store.auth.isLoading {
                    ProgressView("Clearing saved token…")
                }
                if let error = store.auth.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            } else {
                ProgressView("Loading your account…")
            }
        }
        .multilineTextAlignment(.center)
        .disabled(store.auth.isLoading)
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundPrimary)
    }
}

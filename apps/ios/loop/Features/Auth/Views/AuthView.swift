import SwiftUI
import ComposableArchitecture

struct AuthView: View {
    let store: StoreOf<AuthProvider>

    @State private var screen: Screen = .landing

    private enum Screen {
        case landing
        case register
        case login
    }

    var body: some View {
        Group {
            switch screen {
            case .landing:
                LandingView(
                    onRegister: { screen = .register },
                    onLogin: { screen = .login }
                )

            case .register:
                RegisterView(store: store)

            case .login:
                LoginView(store: store)
            }
        }
        .disabled(store.isLoading)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if store.isLoading {
                ProgressView()
                    .padding(DesignSystem.Spacing.sm)
            }

            if let message = store.errorMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(DesignSystem.Spacing.lg)
            }
        }
    }
}

import SwiftUI
import ComposableArchitecture

struct AuthView: View {
    let store: StoreOf<AuthFeature>

    var body: some View {
        switch store.screen {
        case .register:
            RegisterView(store: store)

        case .login:
            LoginView(store: store)

        case .otp:
            OTPView(store: store)
        }
    }
}

import SwiftUI
import ComposableArchitecture

struct AuthView: View {
    let store: StoreOf<AuthProvider>

    var body: some View {
        switch store.screen {
            
        case .landing:
            LandingView(store: store)
            
        case .register:
            RegisterView(store: store)
            
        case .login:
            LoginView(store: store)
        }
    }
}

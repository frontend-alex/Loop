//
//  App.View.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        switch store.route {
        case .splash:
            SplashView {
                store.send(.splashFinished)
            }
        case .auth:
            AuthView(
                store: store.scope(
                    state: \.auth,
                    action: \.auth
                )
            )
        case .onboarding:
            OnboardingView(
                store: store.scope(
                    state: \.onboarding,
                    action: \.onboarding
                )
            )
        case .home:
            HomeView()
        }
    }
}

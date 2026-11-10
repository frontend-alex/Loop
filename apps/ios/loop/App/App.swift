//
//  App.View.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//
import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppProvider>

    var body: some View {
        switch store.route {
        case .splash:
            SplashView {
                store.send(.splashFinished)
            }

        case .auth:
            LandingView(
                store: store.scope(
                    state: \.auth,
                    action: \.auth
                )
            )

        case .loadingUser:
            VStack(spacing: DesignSystem.Spacing.md) {
                if let message = store.userError {
                    Text(message)
                        .multilineTextAlignment(.center)
                    AppButton("Retry") {
                        store.send(.retryUserFetch)
                    }
                } else {
                    ProgressView("Loading your account…")
                }
            }
            .padding(DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.Semantic.backgroundPrimary.ignoresSafeArea())

        case .onboarding:
            OnboardingView(
                store: store.scope(
                    state: \.onboarding,
                    action: \.onboarding
                )
            )

        case .home:
            HomeView(
                store: store.scope(
                    state: \.auth,
                    action: \.auth
                ),
                user: store.user
            )
        }
    }
}

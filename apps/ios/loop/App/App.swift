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
                    .disabled(store.auth.isLoading)

                    AppButton("Clear token and sign in again", variant: .secondary) {
                        store.send(.auth(.logout))
                    }
                    .disabled(store.auth.isLoading)

                    if store.auth.isLoading {
                        ProgressView("Clearing saved token…")
                    }
                    if let error = store.auth.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
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

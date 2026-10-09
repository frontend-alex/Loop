//
//  App.Provider.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//

import ComposableArchitecture

@Reducer
struct AppProvider {
    @ObservableState
    struct State: Equatable {
        enum Route: Equatable {
            case splash
            case auth
            case onboarding
            case home
        }

        var route: Route = .splash
        var auth = AuthProvider.State()
        var onboarding = OnboardingProvider.State()
    }

    enum Action {
        case splashFinished
        case auth(AuthProvider.Action)
        case onboarding(OnboardingProvider.Action)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.auth, action: \.auth) {
            AuthProvider()
        }

        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingProvider()
        }

        Reduce { state, action in
            switch action {
            case .splashFinished:
                return .send(.auth(.task))

            case .auth(.delegate(.authenticated)):
                state.route = .onboarding
                return .none

            case .auth(.delegate(.unauthenticated)):
                state.route = .auth
                return .none

            case .onboarding(.delegate(.completed)):
                state.route = .home
                return .none

            case .auth, .onboarding:
                return .none
            }
        }
    }
}

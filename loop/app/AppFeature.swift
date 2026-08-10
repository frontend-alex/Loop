//
//  AppFeature.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//

import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State : Equatable {
        enum Route: Equatable {
            case splash
            case auth
            case home
            case onboarding
        }
        
        var route: Route = .splash
        var auth = AuthFeature.State()
        var onboarding = OnboardingFeature.State()
    }
    
    enum Action {
        case splashFinished
        case auth(AuthFeature.Action)
        case onboarding(OnboardingFeature.Action)
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .splashFinished:
                state.route = .auth
                return .none
            case .auth(.delegate(.authenticated)):
                state.route = .onboarding
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

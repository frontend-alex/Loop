//
//  Auth.Provider.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//

import ComposableArchitecture

@Reducer
struct AuthProvider {
    @ObservableState
    struct State: Equatable {
        enum Screen: Equatable {
            case landing
            case register
            case login
        }

        var screen: Screen = .landing
        var email = ""
        var password = ""
        var otp = ""
        var isLoading = false
        var errorMessge: String?
    }

    enum Action: Equatable {
        case emailChanged(String)
        case passwordChanged(String)
        case otpChanged(String)

        case registerTapped
        case loginTapped

        case showLogin
        case showRegister

        case delegate(Delegate)

        enum Delegate: Equatable {
            case authenticated
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .emailChanged(value):
                state.email = value
                return .none

            case let .passwordChanged(value):
                state.password = value
                return .none

            case let .otpChanged(value):
                state.otp = value
                return .none

            case .showLogin:
                state.screen = .login
                return .none

            case .showRegister:
                state.screen = .register
                return .none

            case .registerTapped, .loginTapped:
                return .send(.delegate(.authenticated))

            case .delegate:
                return .none
            }
        }
    }
}

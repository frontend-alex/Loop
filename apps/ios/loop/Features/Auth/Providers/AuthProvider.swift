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
        var session: AuthSession?
        var isLoading = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case task
        case showLogin
        case showRegister
        case loginTapped(AuthProviderKind)
        case registerTapped(AuthProviderKind)
        case sessionRestored(AuthSession)
        case authenticationFailed
        case logout
        case delegate(Delegate)

        enum Delegate: Equatable {
            case authenticated
            case unauthenticated
        }
    }

    @Dependency(AuthClient.self)
    private var authClient

    @Dependency(AuthTokenStore.self)
    private var authTokenStore

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true

                return .run { send in
                    do {
                        guard let token = try await authTokenStore.load() else {
                            await send(.delegate(.unauthenticated))
                            return
                        }

                        await send(
                            .sessionRestored(
                                AuthSession(token: token)
                            )
                        )
                    } catch {
                        await send(.delegate(.unauthenticated))
                    }
                }

            case let .loginTapped(provider),
                 let .registerTapped(provider):
                state.isLoading = true
                state.errorMessage = nil

                return .run { send in
                    do {
                        let session = try await authClient.authenticate(provider)
                        try await authTokenStore.save(session.token)

                        await send(.sessionRestored(session))
                    } catch {
                        await send(.authenticationFailed)
                    }
                }

            case let .sessionRestored(session):
                state.session = session
                state.isLoading = false

                return .send(.delegate(.authenticated))

            case .authenticationFailed:
                state.isLoading = false
                state.errorMessage = "Authentication failed."
                return .none

            case .showLogin:
                state.screen = .login
                return .none

            case .showRegister:
                state.screen = .register
                return .none

            case .logout:
                state.session = nil
                state.isLoading = false

                return .run { send in
                    try? await authTokenStore.delete()
                    await send(.delegate(.unauthenticated))
                }

            case .delegate:
                return .none
            }
        }
    }
}

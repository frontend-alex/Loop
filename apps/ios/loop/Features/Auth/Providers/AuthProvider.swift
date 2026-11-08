//
//  Auth.Provider.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AuthProvider {
    @ObservableState
    struct State: Equatable {
        var session: AuthSession?
        var isLoading = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case restoreSession
        case loginTapped(AuthProviderKind)
        case registerTapped(AuthProviderKind)
        case sessionLoaded(AuthSession?)
        case failed(String)
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
            case .restoreSession:
                guard !state.isLoading else { return .none }
                
                state.isLoading = true
                state.errorMessage = nil

                return .run { [authTokenStore] send in
                    let token = try await authTokenStore.load()
                    await send(.sessionLoaded(token.map(AuthSession.init(token:))))
                } catch: { error, send in
                    await send(.failed(error.localizedDescription))
                }

            case let .loginTapped(provider), let .registerTapped(provider):
                
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil

                return .run { [authClient, authTokenStore] send in
                    let session = try await authClient.authenticate(provider)
                    try await authTokenStore.save(session.token)

                    await send(.sessionLoaded(session))
                } catch: { error, send in
                    await send(.failed(error.localizedDescription))
                }

            case let .sessionLoaded(session):
                state.session = session
                state.isLoading = false
                return .send(.delegate(session == nil ? .unauthenticated : .authenticated))

            case .logout:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil

                return .run { [authTokenStore] send in
                    try await authTokenStore.delete()
                    await send(.sessionLoaded(nil))
                } catch: { error, send in
                    await send(.failed(error.localizedDescription))
                }

            case let .failed(message):
                state.isLoading = false
                state.errorMessage = message
                return state.session == nil ? .send(.delegate(.unauthenticated)) : .none

            case .delegate:
                return .none
            }
        }
    }
}

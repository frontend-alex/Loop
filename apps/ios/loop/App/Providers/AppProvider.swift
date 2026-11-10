//
//  App.Provider.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AppProvider {
    var defaults: UserDefaults = .standard

    @Dependency(UserClient.self) private var userClient

    @ObservableState
    struct State: Equatable {
        enum Route: Equatable {
            case splash
            case auth
            case loadingUser
            case onboarding
            case home
        }

        var route: Route = .splash
        var auth = AuthProvider.State()
        var onboarding = OnboardingProvider.State()
        var user: User?
        var userError: String?
    }

    enum Action: Equatable {
        case splashFinished
        case retryUserFetch
        case userFetched(UserResponse)
        case userFetchFailed
        case userUnauthorized
        case auth(AuthProvider.Action)
        case onboarding(OnboardingProvider.Action)
    }

    private nonisolated enum CancelID: Hashable, Sendable {
        case userFetch
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.auth, action: \.auth) {
            AuthProvider()
        }

        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingProvider(defaults: defaults)
        }

        Reduce { state, action in
            switch action {
            case .splashFinished:
                return .send(.auth(.task))

            case .auth(.delegate(.authenticated)), .retryUserFetch:
                guard let token = state.auth.session?.token, !token.isEmpty else {
                    return .send(.auth(.logout))
                }
                state.route = .loadingUser
                state.user = nil
                state.userError = nil

                return .run { [userClient] send in
                    do {
                        let response = try await userClient.fetch(token)
                        try Task.checkCancellation()
                        await send(.userFetched(response))
                    } catch {
                        guard !Task.isCancelled else { return }
                        if let failure = error as? UserClient.Failure,
                           failure == .unauthorized {
                            await send(.userUnauthorized)
                        } else {
                            await send(.userFetchFailed)
                        }
                    }
                }
                .cancellable(id: CancelID.userFetch, cancelInFlight: true)

            case let .userFetched(response):
                guard state.route == .loadingUser else { return .none }
                
                state.user = response.user
                state.userError = nil
                state.onboarding = .restored(
                    from: defaults,
                    userID: response.user.id,
                    isCompleted: !response.requiresOnboarding
                )
                state.route = response.requiresOnboarding ? .onboarding : .home
                
                return response.requiresOnboarding ? .send(.onboarding(.task)) : .none

            case .userFetchFailed:
                guard state.route == .loadingUser else { return .none }
                state.userError = "Could not load your account. Please retry."
                return .none

            case .userUnauthorized:
                guard state.route == .loadingUser else { return .none }
                return .send(.auth(.logout))

            case .auth(.logout),
                 .auth(.delegate(.unauthenticated)):
                
                    state.route = .auth
                    state.user = nil
                    state.userError = nil
                    state.onboarding = OnboardingProvider.State()
                    return .cancel(id: CancelID.userFetch)

            case .onboarding(.delegate(.completed)):
                state.route = .home
                return .none

            case .onboarding(.delegate(.authenticationRequired)):
                return .send(.auth(.logout))

            case .auth, .onboarding:
                return .none
            }
        }
    }
}

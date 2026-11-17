import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        enum Route: Equatable {
            case splash
            case auth
            case loadingUser
            case onboarding
            case home
        }

        var route = Route.splash
        var auth = AuthFeature.State()
        var onboarding = OnboardingFeature.State()
        var user: User?
        var userError: String?
    }

    enum Action: Equatable {
        case splashFinished
        case retryUserFetch
        case userFetched(UserResponse)
        case userFetchFailed
        case userUnauthorized
        case auth(AuthFeature.Action)
        case onboarding(OnboardingFeature.Action)
    }

    nonisolated enum CancelID { case userFetch }

    @Dependency(APIClient.self) var apiClient
    @Dependency(\.defaultAppStorage) var defaults

    var body: some Reducer<State, Action> {
        Scope(state: \.auth, action: \.auth) { AuthFeature() }
        Scope(state: \.onboarding, action: \.onboarding) { OnboardingFeature() }

        Reduce { state, action in
            switch action {
            case .splashFinished:
                return .send(.auth(.task))

            case .auth(.delegate(.authenticated)), .retryUserFetch:
                guard state.auth.session != nil else { return .send(.auth(.logout)) }
                state.route = .loadingUser
                state.user = nil
                state.userError = nil
                return .run { send in
                    do {
                        await send(.userFetched(try await apiClient.fetchUser()))
                    } catch APIClient.Failure.unauthorized {
                        await send(.userUnauthorized)
                    } catch {
                        await send(.userFetchFailed)
                    }
                }
                .cancellable(id: CancelID.userFetch, cancelInFlight: true)

            case let .userFetched(response):
                guard state.route == .loadingUser else { return .none }
                state.user = response.user
                state.onboarding = .restored(
                    from: defaults,
                    userID: response.user.id,
                    isCompleted: !response.requiresOnboarding
                )
                state.route = state.onboarding.isCompleted ? .home : .onboarding
                return .send(.onboarding(.task))

            case .userFetchFailed:
                guard state.route == .loadingUser else { return .none }
                state.userError = "Could not load your account. Please retry."
                return .none

            case .userUnauthorized:
                guard state.route == .loadingUser else { return .none }
                return .send(.auth(.logout))

            case .auth(.delegate(.unauthenticated)):
                state.route = .auth
                state.user = nil
                state.userError = nil
                state.onboarding = OnboardingFeature.State()
                return .merge(
                    [.cancel(id: CancelID.userFetch)]
                        + OnboardingFeature.CancelID.allCases.map { .cancel(id: $0) }
                )

            case .onboarding(.delegate(.completed)):
                state.route = .home
                return .none

            case .auth, .onboarding:
                return .none
            }
        }
    }
}

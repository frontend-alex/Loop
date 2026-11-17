import ComposableArchitecture

@Reducer
struct AuthFeature {
    @ObservableState
    struct State: Equatable {
        var session: AuthSession?
        var isLoading = false
        var isLoginPresented = false
        var errorMessage: String?
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case task
        case getStartedTapped
        case loginTapped(AuthProviderKind)
        case sessionResolved(AuthSession?)
        case sessionRestoreFailed
        case authenticationCancelled
        case authenticationFailed
        case logout
        case logoutSucceeded
        case logoutFailed
        case delegate(Delegate)

        enum Delegate: Equatable {
            case authenticated
            case unauthenticated
        }
    }

    @Dependency(AuthClient.self) var authClient
    @Dependency(AuthTokenStore.self) var authTokenStore

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .delegate:
                return .none

            case .getStartedTapped:
                state.isLoginPresented = true
                return .none

            case .task:
                guard !state.isLoading, state.session == nil else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let token = try await authTokenStore.load()
                        await send(.sessionResolved(token.map(AuthSession.init(token:))))
                    } catch {
                        await send(.sessionRestoreFailed)
                    }
                }

            case let .loginTapped(provider):
                guard !state.isLoading, state.session == nil else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let session = try await authClient.authenticate(provider)
                        try await authTokenStore.save(session.token)
                        await send(.sessionResolved(session))
                    } catch AuthClientError.authenticationCancelled {
                        await send(.authenticationCancelled)
                    } catch {
                        await send(.authenticationFailed)
                    }
                }

            case let .sessionResolved(session):
                state.session = session
                state.isLoading = false
                guard session != nil else { return .send(.delegate(.unauthenticated)) }
                state.isLoginPresented = false
                return .send(.delegate(.authenticated))

            case .sessionRestoreFailed:
                state.isLoading = false
                state.errorMessage = "Could not read your saved session."
                return .send(.delegate(.unauthenticated))

            case .authenticationCancelled:
                state.isLoading = false
                return .none

            case .authenticationFailed:
                state.isLoading = false
                state.errorMessage = "Could not sign in. Please try again."
                return .none

            case .logout:
                guard !state.isLoading, state.session != nil else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        try await authTokenStore.delete()
                        await send(.logoutSucceeded)
                    } catch {
                        await send(.logoutFailed)
                    }
                }

            case .logoutSucceeded:
                state.session = nil
                state.isLoading = false
                state.isLoginPresented = false
                return .send(.delegate(.unauthenticated))

            case .logoutFailed:
                state.isLoading = false
                state.errorMessage = "Could not sign out. Please try again."
                return .none
            }
        }
    }
}

//
//  Login.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/08/2026.
//

import SwiftUI
import ComposableArchitecture

struct LoginView: View {
    let store: StoreOf<AuthProvider>

    var body: some View {
        VStack() {
            GeometricBackground()
                .aspectRatio(2.67 / 4.0, contentMode: .fit)
            
            Spacer(minLength: 0)
            
            VStack(spacing: 16) {
                AppButton(
                    fullWidth: true,
                    backgroundColor:DesignSystem.Semantic.foregroundPrimary,
                    foregroundColor: DesignSystem.Semantic.foregroundInverse,
                    action: {
                        store.send(.loginTapped)
                    }
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                        Text("Sign in with Apple")
                    }
                }
                
                AppButton(
                    variant: .secondary,
                    fullWidth: true,
                    action: {
                        store.send(.loginTapped)
                    }
                ) {
                    HStack(spacing: 8) {
                        Image("GoogleIcon")
                        Text("Sign in with Google")
                    }
                }
                
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
    }
}

#Preview("Login Screen") {
    LoginView(
        store: Store(
            initialState: AuthProvider.State(screen: .login)
        ) {
            AuthProvider()
        }
    )
}

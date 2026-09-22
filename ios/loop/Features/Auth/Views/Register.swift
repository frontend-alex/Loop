//
//  Register.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/08/2026.
//
import SwiftUI
import ComposableArchitecture

struct RegisterView: View {
    let store: StoreOf<AuthProvider>
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack() {
            GeometricBackground()
                .aspectRatio(2.67 / 4.0, contentMode: .fit)
            
            Spacer(minLength: 0)
            
            VStack(spacing: 16) {
                AppButton(
                    backgroundColor: .black,
                    foregroundColor: .white,
                    action: {
                        store.send(.registerTapped)
                    }
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                        Text("Sign up with Apple")
                    }
                }
                
                AppButton(
                    backgroundColor: .white,
                    foregroundColor: .black,
                    action: {
                        store.send(.registerTapped)
                    }
                ) {
                    HStack(spacing: 8) {
                        Image("GoogleIcon")
                        Text("Sign up with Apple")
                    }
                }
                
                Text("By signing up you agree to our \(Text("Terms").bold().underline()) and \(Text("Privacy Policy").bold().underline())")
                    .font(.caption)
                
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

#Preview {
    RegisterView(store: Store(
        initialState: AuthProvider.State(screen: .login)
    ) {
        AuthProvider()
    }
                 
    )
}

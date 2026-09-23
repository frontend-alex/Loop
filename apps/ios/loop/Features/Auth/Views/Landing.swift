//
//  Landing.swift
//  loop
//
//  Created by Aleksander Ivanov on 22/09/2026.
//
import SwiftUI
import ComposableArchitecture

struct LandingView: View {
    let store: StoreOf<AuthProvider>
    
    var body: some View {
        VStack() {
            GeometricBackground()
                .aspectRatio(2.67 / 4.0, contentMode: .fit)
            
            Spacer(minLength: 0)
            
            VStack(spacing: 16) {
                AppButton(
                    "Get Started",
                    action: {
                        store.send(.showRegister)
                    }
                )
                
                AppButton(
                    "Already have an account?",
                    variant: .secondary,
                    action: {
                        store.send(.showLogin)
                    }
                )
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
    LandingView(store: Store(
        initialState: AuthProvider.State(screen: .landing)
    ) {
        AuthProvider()
    }
                 
    )
}

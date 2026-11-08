//
//  Landing.swift
//  loop
//
//  Created by Aleksander Ivanov on 22/09/2026.
//
import SwiftUI

struct LandingView: View {
    let onRegister: () -> Void
    let onLogin: () -> Void
    
    var body: some View {
        VStack() {
            GeometricBackground()
                .aspectRatio(2.67 / 4.0, contentMode: .fit)
            
            Spacer(minLength: 0)
            
            VStack(spacing: 16) {
                AppButton(
                    "Get Started",
                    action: onRegister
                )
                
                AppButton(
                    "Already have an account?",
                    variant: .secondary,
                    action: onLogin
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
    LandingView(onRegister: {}, onLogin: {})
}

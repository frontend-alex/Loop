//
//  OTP.View.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//

import SwiftUI
import ComposableArchitecture

struct OTPView: View {
    let store: StoreOf<AuthProvider>

    var body: some View {
        VStack(spacing: 16) {
            TextField(
                "Verification code",
                text: Binding(
                    get: { store.otp },
                    set: { store.send(.otpChanged($0)) }
                )
            )

            Button("Verify") {
                store.send(.otpSubmitted)
            }
        }
        .padding()
    }
}

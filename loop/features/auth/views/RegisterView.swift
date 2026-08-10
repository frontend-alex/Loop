//
//  RegisterView.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/08/2026.
//
import SwiftUI
import ComposableArchitecture

struct RegisterView: View {
    let store: StoreOf<AuthFeature>

    var body: some View {
        VStack(spacing: 16) {
            TextField(
                "Email",
                text: Binding(
                    get: { store.email },
                    set: { store.send(.emailChanged($0)) }
                )
            )

            SecureField(
                "Password",
                text: Binding(
                    get: { store.password },
                    set: { store.send(.passwordChanged($0)) }
                )
            )

            Button("Register") {
                store.send(.registerTapped)
            }

            Button("Already have an account? Login") {
                store.send(.showLogin)
            }
        }
        .padding()
    }
}

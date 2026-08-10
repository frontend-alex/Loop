//
//  LoginView.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/08/2026.
//

import SwiftUI
import ComposableArchitecture

struct LoginView: View {
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

            Button("Login") {
                store.send(.loginTapped)
            }

            Button("Create an account") {
                store.send(.showRegister)
            }
        }
        .padding()
    }
}

//
//  Home.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/08/2026.
//

import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    let store: StoreOf<AuthProvider>
    
    var body: some View {
        Text("Home")
        AppButton(
            "Logout",
            action: {
                store.send(.logout)
            }
        )
    }
}

//
//  Home.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/08/2026.
//
import SwiftUI

struct HomeView: View {
    
    let isLoggingOut: Bool
    let logoutError: String?
    let onLogout: () -> Void

    var body: some View {
        VStack {
            Text("Home")
            AppButton("Logout", action: onLogout)
                .disabled(isLoggingOut)

            if let logoutError {
                Text(logoutError)
                    .foregroundStyle(.red)
            }
        }
    }
}

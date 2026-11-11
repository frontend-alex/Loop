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
    let user: User?
    
    var body: some View {
        Form {
            Section("User") {
                if let user {
                    AsyncImage(url: URL(string: user.avatarURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Profile picture")

                    LabeledContent("ID", value: String(user.id))
                    LabeledContent("Name", value: user.name)
                    LabeledContent("Email", value: user.email)
                    LabeledContent(
                        "Created", value: user.createdAt.formatted(date: .abbreviated, time: .shortened)
                    )
                    LabeledContent(
                        "Updated", value: user.updatedAt.formatted(date: .abbreviated, time: .shortened)
                    )
                } else {
                    Text("No user data available.")
                }
            }
            .textSelection(.enabled)

            Section {
                AppButton("Logout") {
                    store.send(.logout)
                }
            }
        }
    }
}

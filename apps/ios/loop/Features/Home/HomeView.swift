import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    let store: StoreOf<AuthFeature>
    let user: User?

    var body: some View {
        Form {
            Section("User") {
                if let user {
                    AsyncImage(url: URL(string: user.avatarURL)) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(.circle)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Profile picture")

                    LabeledContent("ID", value: String(user.id))
                    LabeledContent("Name", value: user.name)
                    LabeledContent("Email", value: user.email)
                    LabeledContent("Created", value: user.createdAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Updated", value: user.updatedAt.formatted(date: .abbreviated, time: .shortened))
                } else {
                    Text("No user data available.")
                }
            }
            .textSelection(.enabled)

            Section {
                Button("Logout") { store.send(.logout) }
                    .buttonStyle(.app)
            }
        }
    }
}

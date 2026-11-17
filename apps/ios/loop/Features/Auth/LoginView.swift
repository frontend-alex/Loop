import ComposableArchitecture
import SwiftUI

struct LoginView: View {
    let store: StoreOf<AuthFeature>

    @State private var showsProviders = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let steps = [
        ("01", "Your alarm rings.\nApps you pick lock."),
        ("02", "Do one Wake-up Task:\nwalk, stretch, a puzzle."),
        ("03", "Apps unlock.\nYour Loop Index moves.")
    ]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: 0) {
                ForEach(steps, id: \.0) { number, text in
                    Divider()
                    HStack(spacing: Spacing.xl) {
                        Text(number).font(.system(size: 72))
                        Text(text).fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.vertical, 25)
                    .padding(.horizontal, Spacing.md)
                    Divider()
                }
            }

            Spacer()

            VStack(spacing: Spacing.lg) {
                Button("Get Started") { showsProviders = true }
                    .buttonStyle(.app)

                Text("By proceeding, you agree to our \(Text("Terms").bold().underline()) and \(Text("Privacy Policy").bold().underline())")
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $showsProviders) {
            NavigationStack {
                VStack(spacing: Spacing.lg) {
                    Button("Continue with Apple", systemImage: "apple.logo") { login(.apple) }
                        .buttonStyle(.app(tint: .foregroundPrimary, foreground: .foregroundInverse))

                    Button { login(.google) } label: {
                        Label { Text("Continue with Google") } icon: { Image("GoogleIcon") }
                    }
                    .buttonStyle(.app(.secondary))
                }
                .padding(Spacing.lg)
                .navigationTitle("Get started")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tint(.textPrimary)
            .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(200)])
            .presentationDragIndicator(.visible)
        }
    }

    private func login(_ provider: AuthProviderKind) {
        showsProviders = false
        store.send(.loginTapped(provider))
    }
}

#Preview {
    LoginView(store: Store(initialState: AuthFeature.State()) { AuthFeature() })
}

import ComposableArchitecture
import SwiftUI

struct LandingView: View {
    @Bindable var store: StoreOf<AuthFeature>

    @State private var filledCount = 0
    private let dotCount = 16

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: 4), spacing: Spacing.md) {
                    ForEach(0..<dotCount, id: \.self) { index in
                        Circle()
                            .fill(index < filledCount ? Color.foregroundPrimary : .backgroundSecondary)
                            .aspectRatio(1, contentMode: .fit)
                            .scaleEffect(index < filledCount ? 1 : 0.94)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: filledCount)

                Spacer()

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Loop")
                        .font(.system(size: 72))
                        .padding(.bottom, -10)
                    Text("Wake up. Do one thing. Then your phone.")

                    Button("Get Started") { store.send(.getStartedTapped) }
                        .buttonStyle(.app)
                }
            }
            .padding(.horizontal, Spacing.md)
            .navigationDestination(isPresented: $store.isLoginPresented) {
                LoginView(store: store)
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(1200))
                    filledCount = filledCount < dotCount ? filledCount + 1 : 0
                }
            }
        }
    }
}

#Preview {
    LandingView(store: Store(initialState: AuthFeature.State()) { AuthFeature() })
}

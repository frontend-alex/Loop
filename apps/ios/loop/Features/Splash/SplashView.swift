import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    var body: some View {
        VStack {
            Image(systemName: "circle.circle").font(.system(size: 60))
            Text("Loop").font(.largeTitle)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .task {
            try? await Task.sleep(for: .seconds(2))
            onFinished()
        }
    }
}

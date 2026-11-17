import SwiftUI

extension View {
    func onSwipeBack(isEnabled: Bool = true, perform action: @escaping () -> Void) -> some View {
        contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        guard isEnabled else { return }
                        guard value.startLocation.x < 40 else { return }
                        guard value.translation.width > 80 else { return }
                        guard abs(value.translation.height) < 80 else { return }

                        action()
                    }
            )
    }
}

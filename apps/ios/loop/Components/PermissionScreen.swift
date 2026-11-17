import SwiftUI

/// A permission prompt: an illustrated phone mock-up above a title, description and two actions.
struct PermissionScreen<Illustration: View>: View {
    let title: String
    let description: String
    let primaryTitle: String
    let secondaryTitle: String
    var isPrimaryEnabled = true
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    @ViewBuilder let illustration: Illustration

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            if !reduceMotion && !dynamicTypeSize.isAccessibilitySize {
                PhoneMockup { illustration }
                    .frame(maxWidth: 200)
                    .accessibilityHidden(true)
            }

            VStack(spacing: Spacing.lg) {
                Text(title)
                    .font(.title.bold())
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button(primaryTitle, action: primaryAction)
                    .buttonStyle(.app)
                    .disabled(!isPrimaryEnabled)
                Button(secondaryTitle, action: secondaryAction)
                    .buttonStyle(.app(.ghost))
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity)
            .background {
                Rectangle()
                    .fill(colorScheme == .dark ? Color.black : .white)
                    .blur(radius: 25)
                    .padding(-80)
                    .ignoresSafeArea()
            }
        }
    }
}

/// A 402×874pt iPhone outline scaled to fit its container.
private struct PhoneMockup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 55)
                        .fill(Color.primary.opacity(0.15))
                        .overlay(alignment: .top) {
                            HStack(spacing: Spacing.sm) {
                                Text("9:41").padding(.leading, 24)
                                Spacer(minLength: 0)
                                Image(systemName: "wifi")
                                Image(systemName: "battery.50percent")
                            }
                            .font(.system(size: 18, weight: .medium))
                            .frame(height: 37)
                            .padding(.horizontal, 35)
                            .offset(y: 18)
                        }
                        .overlay(alignment: .top) {
                            Capsule().fill(.black).frame(width: 120, height: 37).offset(y: 15)
                        }

                    ZStack {
                        RoundedRectangle(cornerRadius: 62).stroke(.orange, lineWidth: 12)
                        RoundedRectangle(cornerRadius: 62).stroke(.black, lineWidth: 4)
                        RoundedRectangle(cornerRadius: 58).stroke(.black, lineWidth: 6).padding(4)
                    }
                    .padding(-7)

                    content
                }
                .frame(width: 402, height: 874)
            }
            .visualEffect { content, proxy in
                content.scaleEffect(min(proxy.size.width / 402, proxy.size.height / 874), anchor: .top)
            }
            .aspectRatio(402 / 874, contentMode: .fit)
    }
}

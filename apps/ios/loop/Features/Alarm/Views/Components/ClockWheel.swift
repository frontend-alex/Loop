import SwiftUI

struct ClockWheel: View {
    @Binding var value: Int
    let count: Int
    let label: String
    let isMirrored: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var textScale: CGFloat = 1
    @State private var selectedID: Int?
    @Namespace private var viewportSpace

    private static let cycleCount = 9
    private static let middleCycle = cycleCount / 2

    init(value: Binding<Int>, count: Int, label: String, isMirrored: Bool) {
        self._value = value
        self.count = count
        self.label = label
        self.isMirrored = isMirrored
        self._selectedID = State(initialValue: count * Self.middleCycle - (value.wrappedValue % count + count) % count)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let height = max(geometry.size.height, 1)
            // The circle touches the middle seam and exits at the outer corners.
            let radius = max((width * width + height * height / 4) / (2 * width), width * 1.05)
            let centerX = isMirrored ? radius : width - radius
            let numberRadius = radius - width * 0.28
            let rowHeight = height * 0.155
            let angleStep = asin(min(rowHeight / numberRadius, 0.9))
            let direction: CGFloat = isMirrored ? -1 : 1
            let tilt = reduceMotion ? 0.0 : 0.18
            let fontSize = min(min(width * 0.4, 84) * textScale, width * 0.46)

            ZStack {
                Circle()
                    .fill(DesignSystem.Semantic.backgroundSecondary)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: centerX, y: height / 2)

                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        // Repeated cycles let a flick pass through 23/00 and 59/00.
                        ForEach(0..<(count * Self.cycleCount), id: \.self) { index in
                            Text(String(format: "%02d", wrapped(-index)))
                                .font(.system(
                                    size: fontSize,
                                    weight: .regular
                                ))
                                .monospacedDigit()
                                .foregroundStyle(DesignSystem.Semantic.textPrimary)
                                .frame(width: width, height: rowHeight)
                                .visualEffect { [viewportSpace] content, row in
                                    let rowFrame = row.frame(in: .named(viewportSpace))
                                    let midY = rowFrame.midY
                                    let progress = (midY - height / 2) / rowHeight
                                    let angle = progress * angleStep
                                    let distance = abs(progress)
                                    let scale: CGFloat = max(0.48, 1 - distance * 0.17)
                                    let opacity = Double(max(0, 1 - distance * 0.26))
                                    let rotation = Angle.radians(Double(-direction * angle) * tilt)
                                    let offset = CGSize(
                                        width: centerX + direction * numberRadius * cos(angle) - rowFrame.midX,
                                        height: height / 2 + numberRadius * sin(angle) - midY
                                    )

                                    return content
                                        .scaleEffect(scale)
                                        .opacity(opacity)
                                        .rotationEffect(rotation)
                                        .offset(offset)
                                }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.vertical, (height - rowHeight) / 2)
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .never, anchor: .center))
                .scrollPosition(id: $selectedID, anchor: .center)
                .onScrollPhaseChange { _, phase in
                    if phase == .idle { recenterIfNeeded() }
                }
                .transaction { transaction in
                    // Page transitions must not animate the wheel's initial scroll position.
                    transaction.animation = nil
                }
            }
            .frame(width: width, height: height)
            .coordinateSpace(name: viewportSpace)
            .clipped()
            .contentShape(Rectangle())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(String(format: "%02d", value))
        .accessibilityHint("Swipe up or down to adjust")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = wrapped(value + 1)
            case .decrement: value = wrapped(value - 1)
            @unknown default: break
            }
        }
        .sensoryFeedback(.selection, trigger: value)
        .onChange(of: selectedID) { _, id in
            guard let id else { return }
            let selected = wrapped(-id)
            if value != selected { value = selected }
        }
        .onChange(of: value) { _, newValue in
            guard let id = selectedID, wrapped(-id) != wrapped(newValue) else { return }
            let delta = wrapped(wrapped(-id) - newValue)
            selectedID = id + (delta > count / 2 ? delta - count : delta)
        }
    }

    private func wrapped(_ number: Int) -> Int {
        (number % count + count) % count
    }

    private func recenterIfNeeded() {
        guard let id = selectedID, id < count || id >= count * (Self.cycleCount - 1) else { return }
        // Recenter only after deceleration, without changing the displayed value.
        withTransaction(Transaction(animation: nil)) {
            selectedID = count * Self.middleCycle - wrapped(value)
        }
    }
}

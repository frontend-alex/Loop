import SwiftUI

/// A controlled, 24-hour time picker. Each half is an independently rotating dial.
struct ClockTimePicker: View {
    @Binding var selection: Date
    /// Shows the same dials without responding to touch, e.g. to recap a time set elsewhere.
    var isReadOnly = false

    @Environment(\.calendar) private var calendar
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var textScale: CGFloat = 1

    private var hours: Binding<Int> {
        Binding(
            get: { calendar.component(.hour, from: selection) },
            set: { setTime(hour: $0, minute: calendar.component(.minute, from: selection)) }
        )
    }

    private var minutes: Binding<Int> {
        Binding(
            get: { calendar.component(.minute, from: selection) },
            set: { setTime(hour: calendar.component(.hour, from: selection), minute: $0) }
        )
    }

    var body: some View {
        GeometryReader { geometry in
            if isReadOnly {
                wheels
                    .allowsHitTesting(false)
            } else if dynamicTypeSize.isAccessibilitySize {
                DatePicker("Time", selection: $selection, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if geometry.size.height < 240 {
                DatePicker("Time", selection: $selection, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                wheels
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("clock-time-picker")
    }

    private var wheels: some View {
        GeometryReader { geometry in
            let wheelWidth = max((geometry.size.width - Spacing.lg) / 2, 1)
            let fontSize = ClockWheel.fontSize(
                width: wheelWidth, height: max(geometry.size.height, 1), textScale: textScale
            )

            HStack(spacing: Spacing.lg) {
                ClockWheel(value: hours, count: 24, label: "Hours, 24-hour clock", isMirrored: false)
                ClockWheel(value: minutes, count: 60, label: "Minutes", isMirrored: true)
            }
            .overlay {
                // Sits in the gap, level with the selected numbers and matching them.
                Text(":")
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                    .offset(y: -fontSize * 0.06)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    private func setTime(hour: Int, minute: Int) {
        guard let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selection) else {
            return
        }
        selection = date
    }
}


private struct ClockWheel: View {
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

    /// Number size for a wheel of this size. Capped by row height so short wheels never overlap their numbers.
    static func fontSize(width: CGFloat, height: CGFloat, textScale: CGFloat) -> CGFloat {
        min(min(width * 0.4, 84) * textScale, width * 0.46, height * 0.155 * 0.95)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let height = max(geometry.size.height, 1)
            // The circle touches the middle seam and exits at the outer corners.
            let radius = max((width * width + height * height / 4) / (2 * width), width * 1.05)
            let centerX = isMirrored ? radius : width - radius
            let numberRadius = radius - width * 0.28
            let fontSize = Self.fontSize(width: width, height: height, textScale: textScale)
            let rowHeight = height * 0.155
            let angleStep = asin(min(rowHeight / numberRadius, 0.9))
            let direction: CGFloat = isMirrored ? -1 : 1
            let tilt = reduceMotion ? 0.0 : 0.18

            ZStack {
                Circle()
                    .fill(Color.backgroundSecondary)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: centerX, y: height / 2)

                ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        // Repeated cycles let a flick pass through 23/00 and 59/00.
                        ForEach(0..<(count * Self.cycleCount), id: \.self) { index in
                            // The selected row is bold and full strength; the rest recede.
                            let isSelected = index == selectedID
                            Text(String(format: "%02d", wrapped(index)))
                                .font(.system(size: fontSize, weight: isSelected ? .semibold : .regular))
                                .monospacedDigit()
                                .foregroundStyle(isSelected ? Color.textPrimary : .textSecondary)
                                .fixedSize()
                                .frame(width: width, height: rowHeight)
                                .visualEffect { [viewportSpace] content, row in
                                    let rowFrame = row.frame(in: .named(viewportSpace))
                                    let midY = rowFrame.midY
                                    let progress = (midY - height / 2) / rowHeight
                                    let angle = progress * angleStep
                                    let distance = abs(progress)
                                    let scale: CGFloat = max(0.48, 1 - distance * 0.22)
                                    let opacity = Double(max(0, 1 - distance * 0.35))
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
                .onAppear {
                    // Set once the wheel has its size; an initial value lands a row off.
                    let id = count * Self.middleCycle + wrapped(value)
                    selectedID = id
                    proxy.scrollTo(id, anchor: .center)
                }
                .onChange(of: height) {
                    // The wheel can resize after appearing (e.g. when bars settle); keep the selection centered.
                    if let selectedID { proxy.scrollTo(selectedID, anchor: .center) }
                }
                .onScrollPhaseChange { _, phase in
                    guard phase == .idle else { return }
                    recenterIfNeeded()
                    // Paging can come to rest slightly off a row; settle exactly on the selection.
                    guard let id = selectedID else { return }
                    withAnimation(.snappy(duration: 0.2)) { proxy.scrollTo(id, anchor: .center) }
                }
                .transaction { transaction in
                    // Page transitions must not animate the wheel's initial scroll position.
                    if transaction.animation != .snappy(duration: 0.2) { transaction.animation = nil }
                }
                }
            }
            .frame(width: width, height: height)
            .coordinateSpace(name: viewportSpace)
            // Not clipped: the circles run past the wheel's frame. Callers draw the picker behind
            // their headings (`zIndex(-1)`); the numbers stay inside the scroll view.
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
            let selected = wrapped(id)
            if value != selected { value = selected }
        }
        .onChange(of: value) { _, newValue in
            guard let id = selectedID, wrapped(id) != wrapped(newValue) else { return }
            let delta = wrapped(newValue - wrapped(id))
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
            selectedID = count * Self.middleCycle + wrapped(value)
        }
    }
}

#Preview("Two-circle clock") {
    @Previewable @State var time = Calendar.current.date(
        bySettingHour: 10, minute: 50, second: 0, of: .now
    ) ?? .now

    ClockTimePicker(selection: $time)
        .frame(height: 560)
}

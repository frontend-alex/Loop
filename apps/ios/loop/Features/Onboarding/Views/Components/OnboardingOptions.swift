import SwiftUI

struct OnboardingOptions: View {
    let options: [String]
    let selected: Set<String>
    let onSelect: (String) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            let columnCount = dynamicTypeSize.isAccessibilitySize ? 1 : 2
            let rowCount = max(1, (options.count + columnCount - 1) / columnCount)
            let spacing = DesignSystem.Spacing.md
            let tileWidth = max(0, (geometry.size.width - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount))
            let tileHeight = max(44, min(
                tileWidth / (dynamicTypeSize.isAccessibilitySize ? 2 : 0.8),
                (geometry.size.height - spacing * CGFloat(rowCount - 1)) / CGFloat(rowCount)
            ))

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount),
                spacing: spacing
            ) {
                ForEach(options, id: \.self) { option in
                    OnboardingOptionCard(title: option, isSelected: selected.contains(option)) {
                        onSelect(option)
                    }
                    .frame(height: tileHeight)
                }
            }
            .frame(height: geometry.size.height)
        }
    }
}

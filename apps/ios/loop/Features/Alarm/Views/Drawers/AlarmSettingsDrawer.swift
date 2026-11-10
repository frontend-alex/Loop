import SwiftUI

struct AlarmSettingsDrawer<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: { dismiss() })
                    }
                }
        }
        .tint(DesignSystem.Semantic.textPrimary)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

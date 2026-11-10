//
//  AppBlocking.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/09/2026.
//
import SwiftUI
import FamilyControls
import ComposableArchitecture

struct AppBlockingView<Heading: View>: View {
    @Bindable var store: StoreOf<AppBlockingProvider>
    @ViewBuilder var heading: () -> Heading

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            switch store.authorizationStatus {

            case .authorized:
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    heading()

                    FamilyActivityPicker(selection: $store.selection.sending(\.selectionChanged))
                        .scrollContentBackground(.hidden)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .mask {
                            if reduceTransparency {
                                Rectangle()
                            } else {
                                VStack(spacing: 0) {
                                    LinearGradient(
                                        colors: [.clear, .black],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: DesignSystem.Spacing.lg)

                                    Rectangle()

                                    LinearGradient(
                                        colors: [.black, .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: DesignSystem.Spacing.lg)
                                }
                            }
                        }
                        .background(DesignSystem.Semantic.backgroundPrimary)
                        .padding(.horizontal, -DesignSystem.Spacing.lg)
                }

            case .unknown, .requesting, .denied:
                Spacer()
                
                AppBlockingPermission(
                    showsBackground: false,
                    title: "Protect your focus",
                    description: "Loop needs permission to restrict distracting apps during a focus session.",
                    primaryActionTitle: "Enable App Blocking",
                    secondaryActionTitle: "Skip for Now",
                    isPrimaryActionEnabled: store.authorizationStatus != .requesting,
                    primaryAction: { store.send(.authorizationRequested) },
                    secondaryAction: { store.send(.permissionSkipped) }
                )
            }

            if let message = store.errorMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(DesignSystem.Palette.danger600)
                    .multilineTextAlignment(.center)
            }
        }
        .task {
            store.send(.task)
        }
    }
}

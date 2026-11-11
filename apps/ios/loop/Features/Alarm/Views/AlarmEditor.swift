//
//  AlarmEditor.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//
import SwiftUI
import ComposableArchitecture
import UIKit

struct AlarmView<Heading: View>: View {
    @Bindable var store: StoreOf<AlarmProvider>
    var isNavigationLocked = false
    @ViewBuilder var heading: () -> Heading
    
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            if true {
                alarmContent
            } else {
                Spacer()
                
                AlarmPermission(
                    tint: DesignSystem.Palette.brand500,
                    showsBackground: false,
                    title: "Never sleep through an alarm",
                    description: permissionDescription,
                    primaryActionTitle: store.authorizationStatus == .denied
                    ? "Open Settings"
                    : "Enable Alarm Access",
                    secondaryActionTitle: "Ask Later",
                    isPrimaryActionEnabled: store.authorizationStatus != .requesting,
                    primaryAction: {
                        if store.authorizationStatus == .denied {
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            openURL(settingsURL)
                        } else {
                            store.send(.authorizationRequested)
                        }
                    },
                    secondaryAction: {
                        store.send(.permissionSkipped)
                    }
                )
            }
            if let message = store.errorMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(DesignSystem.Palette.danger600)
                    .multilineTextAlignment(.center)
            }
        }
        .disabled(store.isSaving)
        .task {
            store.send(.authorizationRefreshed)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            store.send(.authorizationRefreshed)
        }
    }
    
    private var permissionDescription: String {
        switch store.authorizationStatus {
        case .denied:
            return "Alarm access is off. Enable it in Settings to start your Morning Lock session."
        case .requesting:
            return "Waiting for the alarm permission response..."
        case .unknown, .authorized:
            return "Loop needs alarm access to begin your Morning Lock session."
        }
    }
    
    private var alarmContent: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            heading()

            VStack(spacing: 0) {
                ClockTimePicker(selection: $store.alarm.time.sending(\.timeChanged))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Alarm time")
                    .onAppear { store.send(.appeared) }

                AlarmPreferences(alarm: $store.alarm)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            } 
            .padding(.horizontal, -DesignSystem.Spacing.lg)
        }
        .padding(.vertical, DesignSystem.Spacing.lg)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AlarmSetupActions(
                store: store,
                isEnabled: !isNavigationLocked,
                setAlarm: { store.send(.saveTapped) }
            )
            .padding(.vertical, DesignSystem.Spacing.lg)
            .background(DesignSystem.Semantic.backgroundPrimary)
        }
    }
}

#Preview {
    AlarmView(
        store: Store(
            initialState: AlarmProvider.State(
                authorizationStatus: .authorized
            )
        ) {
            AlarmProvider()
        }
    ) {
        Text("Set your alarm").font(.title3.bold())
    }
    .safeAreaPadding(.horizontal, DesignSystem.Spacing.lg)
}

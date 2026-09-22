//
//  AlarmEditor.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//
import SwiftUI
import AlarmKit
import ComposableArchitecture
import UIKit

struct AlarmView: View {
    let store: StoreOf<OnboardingProvider>
    let onAlarmChanged: (Alarm) -> Void
    
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var alarm = Alarm(
        scheduledID: nil,
        time: .now.addingTimeInterval(60),
        isRepeating: false,
        repeatDays: [],
        label: "",
        sound: .default,
        snoozeEnabled: true
    )
    
    
    var body: some View {
        Group {
            if store.alarmAuthorizationStatus == .authorized {
                alarmContent
            } else {
                
                AlarmPermission(
                    title: "Never sleep through an alarm",
                    description: permissionDescription,
                    primaryActionTitle: store.alarmAuthorizationStatus == .denied
                    ? "Open Settings"
                    : "Enable Alarm Access",
                    secondaryActionTitle: "Ask Later",
                    isPrimaryActionEnabled: store.alarmAuthorizationStatus != .requesting,
                    primaryAction: {
                        if store.alarmAuthorizationStatus == .denied {
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            openURL(settingsURL)
                        } else {
                            store.send(.alarmAuthorizationRequested)
                        }
                    },
                    secondaryAction: {
                        store.send(.alarmPermissionSkipped)
                    }
                )
            }
        }
        .task {
            refreshAuthorizationState()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshAuthorizationState()
        }
    }
    
    private var permissionDescription: String {
        switch store.alarmAuthorizationStatus {
        case .denied:
            return "Alarm access is off. Enable it in Settings to start your Morning Lock session."
        case .requesting:
            return "Waiting for the alarm permission response..."
        case .unknown, .authorized:
            return "Loop needs alarm access to begin your Morning Lock session."
        }
    }
    
    private func refreshAuthorizationState() {
        switch AlarmManager.shared.authorizationState {
        case .notDetermined:
            store.send(.alarmAuthorizationChecked(.unknown))
        case .denied:
            store.send(.alarmAuthorizationChecked(.denied))
        case .authorized:
            store.send(.alarmAuthorizationChecked(.authorized))
        @unknown default:
            store.send(.alarmAuthorizationChecked(.denied))
        }
    }
    
    private var alarmContent: some View {
        Form {
            Section {
                DatePicker(
                    "Alarm time",
                    selection: $alarm.time,
                    displayedComponents: .hourAndMinute
                )
                .frame(height: 100)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
            
            Section {
                NavigationLink {
                    AlarmRepeatView(
                        selectedDays: Binding(
                            get: { alarm.repeatDays },
                            set: { days in
                                alarm.repeatDays = days
                                alarm.isRepeating = !days.isEmpty
                                onAlarmChanged(alarm)
                            }
                        )
                    )
                    .navigationTitle("Repeat")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar(.visible, for: .navigationBar)
                } label: {
                    HStack {
                        Text("Repeat")
                        
                        Spacer()
                        
                        Text(alarm.repeatSummary)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Text("Label")
                    
                    TextField("Label", text: $alarm.label)
                        .multilineTextAlignment(.trailing)
                        .submitLabel(.done)
                }
                
                Picker("Sound", selection: $alarm.sound) {
                    ForEach(AlarmSound.allCases) { sound in
                        Text(sound.title)
                            .tag(sound)
                    }
                }
                .pickerStyle(.menu)
                .tint(.secondary)
                
                Toggle("Snooze", isOn: $alarm.snoozeEnabled)
            }
        }
        .onChange(of: alarm.time) {
            onAlarmChanged(alarm)
        }
        .onChange(of: alarm.label) {
            onAlarmChanged(alarm)
        }
        .onChange(of: alarm.sound) {
            onAlarmChanged(alarm)
        }
        .onChange(of: alarm.snoozeEnabled) {
            onAlarmChanged(alarm)
        }
        .onAppear {
            onAlarmChanged(alarm)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollDisabled(true)
        .contentMargins(.horizontal, 0.001, for: .scrollContent)
    }
}

#Preview {
    AlarmView(
        store: Store(
            initialState: OnboardingProvider.State(
                alarmAuthorizationStatus: .authorized
            )
        ) {
            OnboardingProvider()
        },
        onAlarmChanged: { _ in }
    )
}

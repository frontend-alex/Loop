//
//  Alarm.View.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//
import SwiftUI
import AlarmKit

struct AlarmView: View {
    let onAlarmChanged: (Alarm) -> Void

    @State private var isAuthorized = false
    @State private var scheduleDate = Date.now.addingTimeInterval(60)
    @State private var isRepeating = false

    var body: some View {
        NavigationStack {
            Group {
                if isAuthorized {
                    alarmContent
                } else {
                    Text("You need to allow alarms in Settings to use this app.")
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .glassEffect()
                }
            }
        }
        .task {
            await checkAndAuthorize()
        }
    }

    private var alarmContent: some View {
        VStack {
            DatePicker(
                "",
                selection: Binding(
                    get: { scheduleDate },
                    set: { date in
                        scheduleDate = date
                        notifyAlarmChanged()
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()

            Toggle(
                "Repeat alarm",
                isOn: Binding(
                    get: { isRepeating },
                    set: { repeating in
                        isRepeating = repeating
                        notifyAlarmChanged()
                    }
                )
            )
        }
        .onAppear {
            notifyAlarmChanged()
        }
    }

    private func notifyAlarmChanged() {
        onAlarmChanged(
            Alarm(
                scheduledID: nil,
                time: scheduleDate,
                isRepeating: isRepeating,
            )
        )
    }

    @MainActor
    private func checkAndAuthorize() async {
        switch AlarmManager.shared.authorizationState {

        case .notDetermined:
            do {
                let status = try await AlarmManager.shared.requestAuthorization()
                isAuthorized = status == .authorized
            } catch {
                print("AlarmKit authorization failed:", error)
                isAuthorized = false
            }
            
        case .denied:
            isAuthorized = false
            
        case .authorized:
            isAuthorized = true
            
        @unknown default:
            isAuthorized = false
        }
    }
}

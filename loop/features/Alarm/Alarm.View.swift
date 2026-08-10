//
//  Alarm.View.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//
import SwiftUI
import AlarmKit
import ActivityKit
import AppIntents

struct AlarmView: View {

    @State private var isAuthorized = false
    @State private var scheduleDate: Date = .now.addingTimeInterval(60)

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
            .navigationTitle("AlarmKit")
        }
        .task {
            await checkAndAuthorize()
        }
    }

    private var alarmContent: some View {
        List {
            Section("Date & Time") {
                DatePicker(
                    "",
                    selection: $scheduleDate,
                    in: Date.now...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }

            Button("Set Alarm") {
                Task {
                    do {
                        try await setAlarm()
                    } catch {
                        print("Failed to schedule alarm:", error)
                    }
                }
            }
        }
    }

    private func setAlarm() async throws {
        
        let id = UUID()
        
        let alert = AlarmPresentation.Alert(
            title: "Alarm",
        )
        
        let presentation = AlarmPresentation(
            alert: alert
        )

        let attributes = AlarmAttributes<AlarmKitMetadata>(
            presentation: presentation,
            metadata: AlarmKitMetadata(),
            tintColor: .orange
        )

        let schedule: AlarmKit.Alarm.Schedule = .fixed(scheduleDate)

        let configuration:
            AlarmManager.AlarmConfiguration<AlarmKitMetadata> = .alarm(
                schedule: schedule,
                attributes: attributes,
                sound: .default
            )

        let alarm = try await AlarmManager.shared.schedule(
            id: id,
            configuration: configuration
        )

        print("Alarm scheduled successfully:", alarm)
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

//private struct AlarmView: View {
//
//    @State private var edit = false
//    @State private var hour = "20"
//    @State private var minute = "30"
//
//    private let hours = (0...23).map {
//        String(format: "%02d", $0)
//    }
//
//    private let minutes = (0...59).map {
//        String(format: "%02d", $0)
//    }
//
//    var body: some View {
//        HStack(spacing: edit ? 20 : 0) {
//
//            AlarmComponent(
//                isLeft: true,
//                edit: $edit,
//                selectedValue: $hour,
//                values: hours,
//                title: "Hr"
//            )
//
//            AlarmComponent(
//                isLeft: false,
//                edit: $edit,
//                selectedValue: $minute,
//                values: minutes,
//                title: "Min"
//            )
//
//            ZStack {
//                if edit {
//                    Image(systemName: "checkmark")
//                        .font(.system(size: 25))
//                        .bold()
//                        .transition(
//                            .blurReplace
//                                .combined(with: .offset(x: -35))
//                        )
//                } else {
//                    Image(systemName: "pencil")
//                        .renderingMode(.template)
//                        .resizable()
//                        .scaledToFit()
//                        .foregroundColor(.primary)
//                        .frame(width: 20, height: 20)
//                        .transition(
//                            .blurReplace
//                                .combined(with: .offset(x: 35))
//                        )
//                }
//            }
//            .padding(.horizontal, 20)
//            .frame(height: edit ? 105 : 60)
//            .background(
//                Color(uiColor: .tertiarySystemBackground),
//                in: UnevenRoundedRectangle(
//                    topLeadingRadius: edit ? 12 : 0,
//                    bottomLeadingRadius: edit ? 12 : 0,
//                    bottomTrailingRadius: 12,
//                    topTrailingRadius: 12
//                )
//            )
//        }
//        .onTapGesture {
//            withAnimation(
//                !edit
//                    ? .smooth(duration: 0.5, extraBounce: 0.5)
//                    : .smooth
//            ) {
//                edit.toggle()
//            }
//        }
//    }
//}

#Preview {
    AlarmView()
}

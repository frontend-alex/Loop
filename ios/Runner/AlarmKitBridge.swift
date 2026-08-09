import AlarmKit
import Flutter
import Foundation
import SwiftUI

final class AlarmKitBridge {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "loop/alarm",
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    Task { @MainActor in
      do {
        switch call.method {
        case "requestAlarmAuthorization":
          result(try await requestAuthorization())
        case "scheduleAlarm":
          try await schedule(arguments: call.arguments)
          result(nil)
        case "cancelAlarm":
          try cancel(arguments: call.arguments)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(
          FlutterError(
            code: "ALARM_ERROR",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }

  private func requestAuthorization() async throws -> Bool {
    let state = try await AlarmManager.shared.requestAuthorization()
    return state == .authorized
  }

  private func schedule(arguments: Any?) async throws {
    guard let values = arguments as? [String: Any] else {
      throw AlarmBridgeError.invalidArguments("payload")
    }

    guard
      let idString = values["id"] as? String,
      let id = UUID(uuidString: idString)
    else {
      throw AlarmBridgeError.invalidArguments("id")
    }

    guard
      let hourValue = values["hour"] as? NSNumber,
      let minuteValue = values["minute"] as? NSNumber,
      let repeatsValue = values["repeat"] as? NSNumber,
      let label = values["label"] as? String
    else {
      throw AlarmBridgeError.invalidArguments("hour, minute, repeat, or label")
    }

    let hour = hourValue.intValue
    let minute = minuteValue.intValue
    let repeats = repeatsValue.boolValue

    guard (0...23).contains(hour), (0...59).contains(minute) else {
      throw AlarmBridgeError.invalidArguments("time")
    }

    guard !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw AlarmBridgeError.invalidArguments("label")
    }

    let time = Alarm.Schedule.Relative.Time(
      hour: hour,
      minute: minute
    )
    let recurrence: Alarm.Schedule.Relative.Recurrence

    if repeats {
      recurrence = .weekly(Self.allWeekdays)
    } else {
      recurrence = .never
    }
    let schedule = Alarm.Schedule.Relative(
      time: time,
      repeats: recurrence
    )

    let stopButton = AlarmButton(
      text: "Dismiss",
      textColor: .white,
      systemImageName: "stop.circle"
    )
    let presentation = AlarmPresentation.Alert(
      title: LocalizedStringResource(stringLiteral: label),
      stopButton: stopButton
    )
    let attributes = AlarmAttributes<LoopAlarmMetadata>(
      presentation: AlarmPresentation(alert: presentation),
      metadata: LoopAlarmMetadata(alarmID: idString),
      tintColor: .blue
    )
    let configuration = AlarmManager.AlarmConfiguration.alarm(
      schedule: .relative(schedule),
      attributes: attributes,
      sound: .default
    )

    if try AlarmManager.shared.alarms.contains(where: { $0.id == id }) {
      try AlarmManager.shared.cancel(id: id)
    }

    _ = try await AlarmManager.shared.schedule(
      id: id,
      configuration: configuration
    )
  }

  private func cancel(arguments: Any?) throws {
    guard
      let values = arguments as? [String: Any],
      let idString = values["id"] as? String,
      let id = UUID(uuidString: idString)
    else {
      throw AlarmBridgeError.invalidArguments("id")
    }

    try AlarmManager.shared.cancel(id: id)
  }

  private static let allWeekdays: [Locale.Weekday] = [
    .monday,
    .tuesday,
    .wednesday,
    .thursday,
    .friday,
    .saturday,
    .sunday,
  ]
}

private struct LoopAlarmMetadata: AlarmMetadata {
  let alarmID: String
}

private enum AlarmBridgeError: LocalizedError {
  case invalidArguments(String)

  var errorDescription: String? {
    switch self {
    case let .invalidArguments(field):
      return "Invalid alarm argument: \(field)."
    }
  }
}

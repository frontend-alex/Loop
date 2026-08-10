//
//  OpenAlarmIntents.swift
//  loop
//
//  Created by Aleksander Ivanov on 05/09/2026.
//

import AppIntents

struct OpenAlarmAppIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Opens App"
    static let openAppWhenRun: Bool = true
    static let isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

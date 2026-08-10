//
//  Onboarding.Models.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//
import Foundation

struct Alarm: Equatable, Codable, Sendable {
    var time: Date
    var weekdays: Set<Int>
}

struct AppSelection: Equatable, Codable, Sendable, Identifiable {
    var id: String
    var name: String
}

struct TaskItem: Equatable, Codable, Sendable, Identifiable {
    var id: UUID
    var title: String
    var dueDate: Date?
}

struct OnboardingDraft: Equatable, Codable, Sendable {
    var alarm: Alarm?
    var distractingApps: [AppSelection] = []
    var tasks: [TaskItem] = []
}

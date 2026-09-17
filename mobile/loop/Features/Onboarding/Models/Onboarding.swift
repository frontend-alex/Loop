//
//  Onboarding.Models.swift
//  loop
//
//  Created by Aleksander Ivanov on 11/08/2026.
//

import Foundation

// MARK: - Onboarding state

struct OnboardingDraft: Equatable, Codable, Sendable {
    var answers: [String: QuestionAnswer] = [:]
    var alarm: Alarm?
    var distractingApps: [AppSelection] = []
    var tasks: [TaskItem] = []
}

// MARK: - Questions

enum QuestionBody: Equatable, Codable, Sendable {
    case single(options: [String])
    case multiple(options: [String])
    case time
}

struct Question: Identifiable, Equatable, Codable, Sendable {
    let id: String
    let heading: String
    let subHeading: String
    let body: QuestionBody

    static let all: [Question] = [
        Question(
            id: "focus",
            heading: "What is your focus?",
            subHeading: "Choose one option.",
            body: .single(options: ["Low", "Medium", "High"])
        ),
        Question(
            id: "distractions",
            heading: "What distracts you?",
            subHeading: "Choose all that apply.",
            body: .multiple(options: ["Social media", "Games", "Messages"])
        ),
        Question(
            id: "wake-time",
            heading: "When should you wake up?",
            subHeading: "Choose a time.",
            body: .time
        ),
        Question(
            id: "goals",
            heading: "What are your goals?",
            subHeading: "Choose all that apply.",
            body: .multiple(options: ["Focus", "Exercise", "Reading"])
        ),
        Question(
            id: "experience",
            heading: "How experienced are you?",
            subHeading: "Choose one option.",
            body: .single(options: ["Beginner", "Intermediate", "Advanced"])
        )
    ]
}

enum QuestionAnswer: Equatable, Codable, Sendable {
    case single(String)
    case multiple(Set<String>)
    case time(Date)
}

// MARK: - App selection

struct AppSelection: Codable, Equatable, Sendable {
    let encodedSelection: Data

    static let empty = AppSelection(
        encodedSelection: Data()
    )
}

// MARK: - Tasks

struct TaskItem: Equatable, Codable, Sendable, Identifiable {
    var id: UUID
    var title: String
    var dueDate: Date?
}

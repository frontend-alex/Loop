//
//  User.swift
//  loop
//
//  Created by Aleksander Ivanov on 09/11/2026.
//

import Foundation

nonisolated struct User: Decodable, Equatable, Sendable {
    let id: Int
    let email: String
    let name: String
    let avatarURL: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case email = "Email"
        case name = "Name"
        case avatarURL = "AvatarURL"
        case createdAt = "CreatedAt"
        case updatedAt = "UpdatedAt"
    }
}

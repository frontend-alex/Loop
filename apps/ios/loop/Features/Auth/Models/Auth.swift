//
//  Auth.swift
//  loop
//
//  Created by Aleksander Ivanov on 09/10/2026.
//

import Foundation

struct AuthResponse: Decodable, Sendable {
    let data: AuthData
}


struct AuthData: Decodable, Sendable {
    let token: String
}

struct AuthSession: Equatable, Sendable {
    let token: String
}

enum AuthProviderKind: String, Equatable, Sendable {
    case google
    case apple
    case github

    var backendPath: String {
        switch self {
        case .google:
            return "google"
        case .apple:
            return "apple"
        case .github:
            return "github"
        }
    }
}

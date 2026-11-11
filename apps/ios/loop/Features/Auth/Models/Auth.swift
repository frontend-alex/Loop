//
//  Auth.swift
//  loop
//
//  Created by Aleksander Ivanov on 09/10/2026.
//

struct AuthSession: Equatable, Sendable {
    let token: String
}

enum AuthProviderKind: String, Equatable, Sendable {
    case google
    case apple
}

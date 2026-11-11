//
//  AppBlockingService.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/09/2026.
//
import FamilyControls

enum AppBlockingService {
    static func requestAuthorization() async throws -> Bool {
        let center = AuthorizationCenter.shared

        if center.authorizationStatus == .approved {
            return true
        }

        try await center.requestAuthorization(for: .individual)

        return center.authorizationStatus == .approved
    }
}

//
//  AppBlockingService.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/09/2026.
//
import FamilyControls
import Foundation

final class AppBlockingService: AppBlockingPort {
    func requestAuthorization() async throws -> Bool {
        let center = AuthorizationCenter.shared

        if center.authorizationStatus == .approved {
            return true
        }

        try await center.requestAuthorization(for: .individual)

        return center.authorizationStatus == .approved
    }

    func saveSelection(_ selection: AppSelection) throws {
        UserDefaults.standard.set(
            selection.encodedSelection,
            forKey: "app-blocking.selection"
        )
    }
}

//
//  MockAppBlocking.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/09/2026.
//
import Foundation

final class _AppBlockingService: AppBlockingPort {
    func requestAuthorization() async throws -> Bool {
        true
    }

    func saveSelection(_ selection: AppSelection) throws {
        UserDefaults.standard.set(
            selection.encodedSelection,
            forKey: "app-blocking.selection"
        )
    }
}

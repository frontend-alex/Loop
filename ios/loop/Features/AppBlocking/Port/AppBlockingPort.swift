//
//  AppBlockingPort.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/09/2026.
//

protocol AppBlockingPort {
    func requestAuthorization() async throws -> Bool
    func saveSelection(_ selection: AppSelection) throws
}

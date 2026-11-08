//
//  AlarmPort.swift
//  loop
//
//  Created by Aleksander Ivanov on 03/11/2026.
//
import Foundation

protocol AlarmPort: Sendable {
    func setAlarm(at date: Date) async throws -> UUID
    
    func cancelAlarm(id: UUID) async throws
}

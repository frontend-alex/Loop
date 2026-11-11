//
//  APIResponse.swift
//  loop
//
//  Created by Aleksander Ivanov on 09/11/2026.
//

nonisolated struct APIResponse<Value: Decodable & Sendable>: Decodable, Sendable {
    let data: Value
}

//
//  CreateUser.swift
//  
//
//  Created by Андрэй Целігузаў on 24.04.23.
//

import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("surname", .string, .required)
            .field("role", .string, .required)
            .field("email", .string, .required)
            .field("username", .string, .required)
            .field("password", .string, .required)
            .unique(on: "name", "surname")
            .unique(on: "email")
            .unique(on: "username")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}

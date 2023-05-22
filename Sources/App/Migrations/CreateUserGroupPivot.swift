//
//  CreateUserGroupPivot.swift
//  
//
//  Created by Андрэй Целігузаў on 24.04.23.
//

import Fluent
import Vapor

struct CreateUserGroupPivot: AsyncMigration{
    func prepare(on database: Database) async throws {
        try await database.schema("user+group")
            .id()
            .field("user", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("group", .uuid, .required, .references("groups", "id", onDelete: .cascade))
            .unique(on: "user", "group")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user+group").delete()
    }
}

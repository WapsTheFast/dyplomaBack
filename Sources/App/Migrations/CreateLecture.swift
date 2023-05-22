//
//  File.swift
//  
//
//  Created by Андрэй Целігузаў on 28.04.23.
//

import Fluent
import Vapor

struct CreateLecture: AsyncMigration{
    
    
    func prepare(on database: Database) async throws {
        try await database.schema("lectures")
            .id()
            .field("name", .string, .required)
            .field("date", .datetime, .required)
            .field("image_path", .string)
            .field("matherial_path", .string)
            .field("group_id", .uuid, .references("groups", "id"))
            .field("creator_id", .uuid, .references("users", "id"))
            .field("subject_id", .uuid, .references("subjects", "id"))
            .unique(on: "name")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("lectures").delete()
    }
    
}

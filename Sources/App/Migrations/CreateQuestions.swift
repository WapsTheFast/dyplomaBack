//
//  CreateQuestions.swift
//
//
//  Created by Андрэй Целігузаў on 28.04.23.
//

import Fluent
import Vapor

struct CreateQuestions: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("questions")
      .id()
      .field("name", .string, .required)
      .field("questions", .json, .required)
      .field("teacher_id", .uuid, .references("users", "id"))
      .field("lecture_id", .uuid, .references("lectures", "id", onDelete: .setNull, onUpdate: .cascade))
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("subjects").delete()
  }

}

//
//  CreateAnswers.swift
//
//
//  Created by Андрэй Целігузаў on 28.04.23.
//

import Fluent

struct CreateAnswers: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("answers")
      .id()
      .field("name", .string, .required)
      .field("answers", .json, .required)
      .field("student_id", .uuid, .references("users", "id"))
      .field("lecture_id", .uuid, .references("lectures", "id"))
      .field("questions_id", .uuid, .references("questions", "id", onDelete: .setNull, onUpdate: .cascade))
      .unique(on: "student_id", "questions_id")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("groups").delete()
  }

}

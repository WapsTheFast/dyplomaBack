//
//  CreateStudentsOnLecture.swift
//
//
//  Created by Андрэй Целігузаў on 28.04.23.
//

import Fluent
import Vapor

struct CreateStudentsOnLecture: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("studentsOnLecture")
      .id()
      .field("state", .string, .required)
      .field("group_id", .uuid, .references("groups", "id"))
      .field(
        "lecture_id", .uuid, .references("lectures", "id", onDelete: .cascade, onUpdate: .cascade)
      )
      .field("student_id", .uuid, .references("users", "id"))
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("studentOnLecture").delete()
  }

}

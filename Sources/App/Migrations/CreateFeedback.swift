//
//  CreateFeedback.swift
//
//
//  Created by Андрэй Целігузаў on 06.06.23.
//

import Fluent

struct CreateFeedback: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("feedback")
      .id()
      .field("text", .string, .required)
      .field("sender_id", .uuid, .references("users", "id"))
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("groups").delete()
  }

}

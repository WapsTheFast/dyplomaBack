//
//  CreateSubject.swift
//
//
//  Created by Андрэй Целігузаў on 28.04.23.
//

import Fluent
import Vapor

struct CreateSubject: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("subjects")
      .id()
      .field("name", .string, .required)
      .unique(on: "name")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("subjects").delete()
  }

}

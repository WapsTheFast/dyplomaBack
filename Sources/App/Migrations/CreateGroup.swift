//
//  CreateGroup.swift
//
//
//  Created by Андрэй Целігузаў on 24.04.23.
//

import Fluent

struct CreateGroup: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("groups")
      .id()
      .field("name", .string, .required)
      .field("course", .string, .required)
      .field("color", .string)
      .field("inviteCode", .int)
      .unique(on: "name")
      .unique(on: "inviteCode")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("groups").delete()
  }

}

//
//  CreateAdminUser.swift
//
//
//  Created by Андрэй Целігузаў on 30.04.23.
//

import Fluent
import Vapor

struct CreateAdminUser: AsyncMigration {

  func prepare(on database: Database) async throws {
    let passwordHash: String
    do {
      passwordHash = try Bcrypt.hash("passwordadmin")
    } catch {
      print("bcrypt error in create admin user")
      return

    }
    let user = User(
      name: "Admin", surname: "Admin", role: "administrator", email: "administrator@email.com",
      username: "admin", password: passwordHash)

    return try await user.save(on: database)
  }

  func revert(on database: Database) async throws {
    try await User.query(on: database).filter(\.$username == "admin").delete()
  }
}

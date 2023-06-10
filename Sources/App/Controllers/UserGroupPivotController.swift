//
//  UserGroupPivotController.swift
//
//
//  Created by Андрэй Целігузаў on 29.04.23.
//

import Fluent
import Vapor

struct UserGroupPivotController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let usersGroups = routes.grouped("api", "users+groups")
    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let tokenAuthGroup = usersGroups.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    tokenAuthGroup.get(use: index)
    tokenAuthGroup.post(use: create)
    tokenAuthGroup.group(":user+groupsID") { usersGroup in
      usersGroup.delete(use: delete)
    }
  }

  func index(req: Request) async throws -> [UserGroup] {
    try await UserGroup.query(on: req.db).all()
  }

  func create(req: Request) async throws -> UserGroup {
    let userGroup = try req.content.decode(UserGroup.self)
    try await userGroup.save(on: req.db)
    return userGroup
  }

  func delete(req: Request) async throws -> HTTPStatus {
    guard let userGroup = try await UserGroup.find(req.parameters.get("user+groupsID"), on: req.db)
    else {
      throw Abort(.notFound)
    }
    try await userGroup.delete(on: req.db)
    return .noContent
  }
}

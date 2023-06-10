//
//  UserController.swift
//
//
//  Created by Андрэй Целігузаў on 24.04.23.
//

import Fluent
import Vapor

struct UserController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let users = routes.grouped("api", "users")
    users.get(use: getAllUsers)
    let basicAuthMiddleware = User.authenticator()
    let basicAuthGroup = users.grouped(basicAuthMiddleware)
    basicAuthGroup.post("login", use: login)
    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let tokenAuthGroup = users.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    users.post(use: create)
    tokenAuthGroup.get(use: getUser)
    tokenAuthGroup.group(":userID") { user in
      user.delete(use: delete)
    }
    tokenAuthGroup.get("groups", use: getGroups)
    tokenAuthGroup.patch("attach", ":inviteCode", use: attatchToGroup)
  }

  func login(_ req: Request) async throws -> Token {
    let user = try req.auth.require(User.self)
    let token = try Token.generate(for: user)
    try await token.save(on: req.db)
    return token
  }

  func getAllUsers(req: Request) async throws -> [User.Public] {
    try await User.query(on: req.db).all().convertToPublic()
  }

  func getUser(_ req: Request) async throws -> User {
    try req.auth.require(User.self)
  }

  func getGroups(_ req: Request) async throws -> [Group] {
    let user = try req.auth.require(User.self)
    return try await user.$groups.get(on: req.db)
  }

  func create(req: Request) async throws -> User.Public {
    let user = try req.content.decode(User.self)
    user.password = try Bcrypt.hash(user.password)
    try await user.save(on: req.db)
    return user.convertToPublic()
  }

  func attatchToGroup(req: Request) async throws -> Group {
    let user: User = try req.auth.require(User.self)
    guard
      let group = try await Group.query(on: req.db)
        .filter(\.$inviteCode == Int(req.parameters.get("inviteCode")!))
        .first()
    else {
      throw Abort(.notFound)
    }
    try await user.$groups.attach(group, on: req.db)
    try await user.save(on: req.db)
    try await group.save(on: req.db)
    return group
  }

  func delete(req: Request) async throws -> HTTPStatus {
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await user.delete(on: req.db)
    return .noContent
  }
}

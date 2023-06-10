//
//  SubjectController.swift
//
//
//  Created by Андрэй Целігузаў on 29.04.23.
//
import Fluent
import Vapor

struct SubjectController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {

    let subject = routes.grouped("api", "subjects")
    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let tokenAuthGroup = subject.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    tokenAuthGroup.get(use: index)
    tokenAuthGroup.post(use: create)
    tokenAuthGroup.group(":subjectID") { subject in
      subject.delete(use: delete)
    }
  }

  func index(req: Request) async throws -> [Subject] {
    try await Subject.query(on: req.db).all()
  }

  func create(req: Request) async throws -> Subject {
    let subject = try req.content.decode(Subject.self)
    try await subject.save(on: req.db)
    return subject
  }

  func delete(req: Request) async throws -> HTTPStatus {
    guard let subject = try await User.find(req.parameters.get("subjectID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await subject.delete(on: req.db)
    return .noContent
  }
}

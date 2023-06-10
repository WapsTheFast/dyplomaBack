//
//  FeedbackController.swift
//
//
//  Created by Андрэй Целігузаў on 29.04.23.
//

import Fluent
import Vapor

struct FeedbackController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let feedback = routes.grouped("api", "feedback")
    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let tokenAuthGroup = feedback.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    tokenAuthGroup.get(use: index)
    tokenAuthGroup.post(use: create)
    tokenAuthGroup.group(":feedbackID") { answers in
      answers.delete(use: delete)
    }
  }

  func index(req: Request) async throws -> [Feedback] {
    try await Feedback.query(on: req.db).all()
  }

  func create(req: Request) async throws -> Feedback {
    let user = try req.auth.require(User.self)
    let text = try req.content.decode(Text.self)
    let feedback = Feedback(text: text.text, userID: user.id!)
    try await feedback.save(on: req.db)
    return feedback
  }

  func delete(req: Request) async throws -> HTTPStatus {
    guard let feedback = try await Feedback.find(req.parameters.get("feedbackID"), on: req.db)
    else {
      throw Abort(.notFound)
    }
    try await feedback.delete(on: req.db)
    return .noContent
  }
}

struct Text: Codable {
  var text: String
}

//
//  QuestionsController.swift
//  
//
//  Created by Андрэй Целігузаў on 29.04.23.
//

import Fluent
import Vapor

struct QuestionsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let questions = routes.grouped("questions")
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = questions.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.get(use: index)
        tokenAuthGroup.post(use: create)
        tokenAuthGroup.group(":questionsID") { questions in
            questions.delete(use: delete)
        }
    }

    func index(req: Request) async throws -> [Questions] {
        try await Questions.query(on: req.db).all()
    }

    func create(req: Request) async throws -> Questions {
        let questions = try req.content.decode(Questions.self)
        try await questions.save(on: req.db)
        return questions
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let questions = try await Questions.find(req.parameters.get("questionsID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await questions.delete(on: req.db)
        return .noContent
    }
}

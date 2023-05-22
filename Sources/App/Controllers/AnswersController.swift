//
//  AnswersController.swift
//  
//
//  Created by Андрэй Целігузаў on 29.04.23.
//

import Fluent
import Vapor

struct AnswersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let answers = routes.grouped("answers")
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = answers.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.get(use: index)
        tokenAuthGroup.post(use: create)
        tokenAuthGroup.group(":answersID") { answers in
            answers.delete(use: delete)
        }
    }

    func index(req: Request) async throws -> [Answers] {
        try await Answers.query(on: req.db).all()
    }

    func create(req: Request) async throws -> Answers {
        let answers = try req.content.decode(Answers.self)
        try await answers.save(on: req.db)
        return answers
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let answers = try await Answers.find(req.parameters.get("answersID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await answers.delete(on: req.db)
        return .noContent
    }
}

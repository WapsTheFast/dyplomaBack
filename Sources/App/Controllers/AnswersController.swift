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
        tokenAuthGroup.put(use: update)
        tokenAuthGroup.get(":lectureID", use: getForTeacher)
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

    func getForTeacher(req : Request) async throws -> [Answers]{
        guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else {
        throw Abort(.notFound)
    }
    
    let answers = try await Answers.query(on: req.db)
        .filter(\.$lecture.$id == lecture.id!)
        .all()
    
    return answers
    }

    func update(req: Request) async throws -> Answers{
        let answers = try req.content.decode(Answers.self)

        guard let oldAnswers = try await Answers.find(answers.id, on: req.db) else{
            throw Abort(.notFound)
        }

        oldAnswers.name = answers.name
        oldAnswers.answers = answers.answers

        try await oldAnswers.update(on: req.db)
        return oldAnswers
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let answers = try await Answers.find(req.parameters.get("answersID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await answers.delete(on: req.db)
        return .noContent
    }
}

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
        tokenAuthGroup.put(use: update)
        tokenAuthGroup.get(":lectureID", use: getForLecture)
        tokenAuthGroup.group(":questionsID") { questions in
            questions.delete(use: delete)
        }

    }

    func index(req: Request) async throws -> [Questions] {
        try await Questions.query(on: req.db).all()
    }

    func getForLecture(req : Request) async throws -> Questions{
        guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else {
        throw Abort(.notFound)
    }
    
    guard let questions = try await Questions.query(on: req.db)
        .filter(\.$lecture.$id == lecture.id!)
        .first() else {
            throw Abort(.notFound)
        }
    
    return questions
    }

    func create(req: Request) async throws -> Questions {
        let questions = try req.content.decode(Questions.self)
        if (try await Questions.find(questions.id, on: req.db)) != nil{
             return try await update(req: req)
        }else{
        try await questions.save(on: req.db)
        return questions
        }
        
    }

    func update(req: Request) async throws -> Questions{
        let questions = try req.content.decode(Questions.self)

        guard let oldQuestions = try await Questions.find(questions.id, on: req.db) else{
            throw Abort(.notFound)
        }

        oldQuestions.name = questions.name
        oldQuestions.questions = questions.questions

        try await oldQuestions.update(on: req.db)
        return oldQuestions
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let questions = try await Questions.find(req.parameters.get("questionsID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await questions.delete(on: req.db)
        return .noContent
    }
}

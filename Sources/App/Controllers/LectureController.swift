//
//  LectureController.swift
//  
//
//  Created by Андрэй Целігузаў on 29.04.23.
//

import Fluent
import Vapor

struct LectureController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let lectures = routes.grouped("lectures")
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = lectures.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.get(use: index)
        tokenAuthGroup.post(use: create)
        tokenAuthGroup.group(":lectureID") { lecture in
            lecture.delete(use: delete)
        }
    }

    func index(req: Request) async throws -> [Lecture] {
        try await Lecture.query(on: req.db).all()
    }

    func create(req: Request) async throws -> Lecture {
        let lecture = try req.content.decode(Lecture.self)
        try await lecture.save(on: req.db)
        return lecture
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await lecture.delete(on: req.db)
        return .noContent
    }
}

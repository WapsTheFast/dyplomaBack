//
//  StudentOnLectureController.swift
//  
//
//  Created by Андрэй Целігузаў on 29.04.23.
//

import Fluent
import Vapor

struct StudentsOnLectureController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let student = routes.grouped("studentsOnLecture")
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = student.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.get(use: index)
        tokenAuthGroup.post(use: create)
        tokenAuthGroup.group(":studentsOnLectureID") { student in
            student.delete(use: delete)
        }
    }

    func index(req: Request) async throws -> [StudentsOnLecture] {
        try await StudentsOnLecture.query(on: req.db).all()
    }

    func create(req: Request) async throws -> StudentsOnLecture {
        let student = try req.content.decode(StudentsOnLecture.self)
        try await student.save(on: req.db)
        return student
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let student = try await StudentsOnLecture.find(req.parameters.get("studentsOnLectureID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await student.delete(on: req.db)
        return .noContent
    }
}

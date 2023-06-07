//
//  GroupController.swift
//  
//
//  Created by Андрэй Целігузаў on 24.04.23.
//

import Fluent
import Vapor

struct GroupController: RouteCollection{
    func boot(routes: Vapor.RoutesBuilder) throws {
        let groups = routes.grouped("groups")
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = groups.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.get(use: index)
        tokenAuthGroup.post(use: create)
        tokenAuthGroup.put(use: update)
        tokenAuthGroup.group(":groupID") { group in
            group.delete(use: delete)
        }
        tokenAuthGroup.get("users", ":groupID", use: getUsers)
        tokenAuthGroup.get("students", ":groupID", use: getStudentsForGroup)
        tokenAuthGroup.get("teachers", ":groupID", use: getTeachersForGroup)
    }
    


    func index(req : Request) async throws -> [Group]{
        try await Group.query(on: req.db).all()
    }
    
    func create(req : Request) async throws -> Group{
        let group = try req.content.decode(Group.self)
        let user = try req.auth.require(User.self)
        try await group.save(on: req.db)
        try await group.$users.attach(user, on: req.db)
        try await group.save(on: req.db)
        try await user.save(on: req.db)
        return group
    }


    func getUsers(req: Request) async throws -> [User]{
        guard let group : Group = try await Group.find(req.parameters.get("groupID"), on: req.db) else{
            throw Abort(.notFound)
        }
        let users : [User] = try await group.$users.get(on: req.db)
        return users
    }

    func getStudentsForGroup(req: Request) async throws -> [User]{
        guard let group : Group = try await Group.find(req.parameters.get("groupID"), on: req.db) else{
            throw Abort(.notFound)
        }
        let users : [User] = try await group.$users.get(on: req.db)
        let students : [User] = users.filter{$0.role == .student}
        return students
    }

    func getTeachersForGroup(req: Request) async throws -> [User]{
        guard let group : Group = try await Group.find(req.parameters.get("groupID"), on: req.db) else{
            throw Abort(.notFound)
        }
        let users : [User] = try await group.$users.get(on: req.db)
        let teachers : [User] = users.filter{$0.role == .teacher}
        return teachers
    }

    func update(req: Request) async throws -> Group{
        let group = try req.content.decode(Group.self)

        guard let oldGroup = try await Group.find(group.id, on: req.db) else{
            throw Abort(.notFound)
        }

        oldGroup.name = group.name
        oldGroup.color = group.color
        oldGroup.course = group.course
        oldGroup.inviteCode = group.inviteCode

        try await oldGroup.update(on: req.db)
        return oldGroup
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let group = try await Group.find(req.parameters.get("groupID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await group.delete(on: req.db)
        return .noContent
    }
    
}

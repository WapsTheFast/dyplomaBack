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
        tokenAuthGroup.group(":groupID") { group in
            group.delete(use: delete)
        }
    }
    
    func index(req : Request) async throws -> [Group]{
        try await Group.query(on: req.db).all()
    }
    
    func create(req : Request) async throws -> Group{
        let group = try req.content.decode(Group.self)
        try await group.save(on: req.db)
        try await group.$users.attach(req.auth.require(User.self), on: req.db)
        try await group.save(on: req.db)
        return group
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let group = try await Group.find(req.parameters.get("groupID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await group.delete(on: req.db)
        return .noContent
    }
    
}

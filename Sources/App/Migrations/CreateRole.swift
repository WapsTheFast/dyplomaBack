//
//  File.swift
//
//
//  Created by Андрэй Целігузаў on 24.04.23.
//

import Fluent

enum Role: String, Codable, CaseIterable {
  case student, teacher, administrator
}

//extension Role: Migration {
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        let roles = Role.allCases.map { $0.rawValue }
//        return database.enum("role")
//            .case(roles[0])
//            .case(roles[1])
//            .case(roles[2])
//            .create()
//            .transform(to: ())
//    }
//
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        return database.enum("role")
//            .delete()
//    }
//}

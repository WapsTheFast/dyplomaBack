//
//  UserGroup.swift
//  
//
//  Created by Андрэй Целігузаў on 24.04.23.
//

import Fluent
import Vapor

final class UserGroup: Model, Content{
    static let schema = "user+group"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user")
    var user : User
    
    @Parent(key: "group")
    var group: Group
    
    init(){}
    
    init(id: UUID? = nil, user : User, group: Group)throws{
        self.id = id
        self.$user.id = try user.requireID()
        self.$group.id = try group.requireID()
    }
}

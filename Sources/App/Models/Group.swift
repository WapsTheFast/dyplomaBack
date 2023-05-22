//
//  Group.swift
//  
//
//  Created by Андрэй Целігузаў on 24.04.23.
//

import Fluent
import Vapor

final class Group: Model, Content{
    static let schema = "groups"
    
    @ID(key: .id)
    var id: UUID?
    
    @Children(for: \.$group)
    var lectures: [Lecture]
    
    @Children(for: \.$group)
    var studentOnLecture : [StudentsOnLecture]
    
    @Siblings(through: UserGroup.self, from: \.$group, to: \.$user)
    var users: [User]
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "course")
    var course: String
    
    @OptionalField(key: "color")
    var color: String?
    
    @OptionalField(key: "inviteCode")
    var inviteCode : Int?
    
    init() {}
    
    init(id : UUID? = nil, name : String, course : String, color: String? = nil, inviteCode: Int? = nil){
        self.id = id
        self.name = name
        self.course = course
        self.color = color
        self.inviteCode = inviteCode
    }
}

//
//  Feedback.swift
//  
//
//  Created by Андрэй Целігузаў on 06.06.23.
//

import Fluent
import Vapor

final class Feedback : Model, Content{
    static let schema = "feedback"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "sender_id")
    var user : User
    
    @Field(key: "text")
    var text: String
    
    init() {}
    
    init(id : UUID? = nil, text : String, userID : User.IDValue){
        self.id = id
        self.text = text
        self.$user.id = userID
    }
}


//
//  Questions.swift
//  
//
//  Created by Андрэй Целігузаў on 28.04.23.
//

import Fluent
import Vapor

final class Questions : Model, Content{
    static let schema = "questions"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "teacher_id")
    var user : User
    
    @Parent(key : "lecture_id")
    var lecture : Lecture
    
    @Children(for: \.$questions)
    var answers: [Answers]
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "questions_path")
    var questionsPath : String
    
    
    init() {}
    
    init(id : UUID? = nil, name : String, questionsPath : String, userID : User.IDValue, lectureID : Lecture.IDValue){
        self.id = id
        self.name = name
        self.questionsPath = questionsPath
        self.$user.id = userID
        self.$lecture.id = lectureID
    }
}

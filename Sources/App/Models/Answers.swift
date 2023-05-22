//
//  Answers.swift
//  
//
//  Created by Андрэй Целігузаў on 28.04.23.
//

import Fluent
import Vapor

final class Answers : Model, Content{
    static let schema = "answers"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "student_id")
    var user : User
    
    @Parent(key : "lecture_id")
    var lecture : Lecture
    
    @Parent(key : "questions_id")
    var questions : Questions
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "answers_path")
    var answersPath : String
    
    
    init() {}
    
    init(id : UUID? = nil, name : String, answersPath : String, userID : User.IDValue, lectureID : Lecture.IDValue, questionsID : Questions.IDValue){
        self.id = id
        self.name = name
        self.answersPath = answersPath
        self.$user.id = userID
        self.$lecture.id = lectureID
        self.$questions.id = questionsID
    }
}

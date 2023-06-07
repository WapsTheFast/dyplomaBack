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
    
    @Field(key: "questions")
    var questions : Test
    
    
    init() {}
    
    init(id : UUID? = nil, name : String, questions : Test, userID : User.IDValue, lectureID : Lecture.IDValue){
        self.id = id
        self.name = name
        self.questions = questions
        self.$user.id = userID
        self.$lecture.id = lectureID
    }
}

struct Test : Codable {
    var testName : String
    var questions : [QuestionsForTest]
}

struct QuestionsForTest : Codable{
    var options : [String]
    var correctAnswersIndices : [Int]
    var questionText : String
}

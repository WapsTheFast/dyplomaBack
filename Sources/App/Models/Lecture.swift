//
//  Lecture.swift
//  
//
//  Created by Андрэй Целігузаў on 28.04.23.
//

import Fluent
import Vapor

enum LectureState : String, Codable, CaseIterable{
    case onGoing, planned, done, archived
}


final class Lecture: Model, Content {
    static let schema = "lectures"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "group_id")
    var group : Group
    
    @Parent(key: "creator_id")
    var user : User
    
    @Parent(key: "subject_id")
    var subject : Subject
    
    @Children(for: \.$lecture)
    var studentsOnLecture : [StudentsOnLecture]
    
    @Children(for: \.$lecture)
    var questions : [Questions]
    
    @Children(for: \.$lecture)
    var answers : [Answers]
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "date")
    var date: Date

    @Enum(key: "state")
    var state: LectureState
    
    @OptionalField(key: "code")
    var code: UUID?
    
    @OptionalField(key: "matherial_path")
    var matherialPath: String?

    init() { }

    init(id: UUID? = nil,
         name: String, 
         date: Date, 
         state: String,
         code: UUID? = nil, 
         matherialPath : String? = nil, 
         groupID : Group.IDValue, 
         userID : User.IDValue, 
         subjectID : Subject.IDValue) {
        self.id = id
        self.name = name
        self.date = date
        switch state{
            case "onGoing":
            self.state = .onGoing
            case "planned":
            self.state = .planned
            case "done":
            self.state = .done
            case "acrchived":
            self.state = .archived
            default:
            self.state = .planned
        }
        self.code = code
        self.matherialPath = matherialPath
        self.$group.id = groupID
        self.$user.id = userID
        self.$subject.id = subjectID
    }
}

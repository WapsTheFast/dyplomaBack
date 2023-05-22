//
//  StudentsOnLecture.swift
//  
//
//  Created by Андрэй Целігузаў on 28.04.23.
//

import Fluent
import Vapor

enum StateOnLecture: String, Codable, CaseIterable{
    case onLecture, notOnLecture, late
}

final class StudentsOnLecture: Model, Content{
    static let schema = "studentsOnLecture"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "group_id")
    var group : Group
    
    @Parent(key: "lecture_id")
    var lecture: Lecture
    
    @Parent(key: "student_id")
    var user : User
    
    @Enum(key: "state")
    var state: StateOnLecture
    
    init() {}
    
    init(id : UUID? = nil, state : String, groupID : Group.IDValue, lectureID : Lecture.IDValue, userID : User.IDValue){
        self.id = id
        self.$group.id = groupID
        self.$lecture.id = lectureID
        self.$user.id = userID
        switch state{
        case "onLecture":
            self.state = .onLecture
        case "notOnLecture":
            self.state = .notOnLecture
        case "late":
            self.state = .late
        default:
            break
        }
    }
}

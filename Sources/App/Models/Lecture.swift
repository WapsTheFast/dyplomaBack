//
//  Lecture.swift
//  
//
//  Created by Андрэй Целігузаў on 28.04.23.
//

import Fluent
import Vapor



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
    
    @OptionalField(key: "image_path")
    var imagePath: String?
    
    @OptionalField(key: "matherial_path")
    var matherialPath: String?

    init() { }

    init(id: UUID? = nil,
         name: String, 
         date: Date, 
         imagePath: String? = nil, 
         matherialPath : String? = nil, 
         groupID : Group.IDValue, 
         userID : User.IDValue, 
         subjectID : Subject.IDValue) {
        self.id = id
        self.name = name
        self.date = date
        self.imagePath = imagePath
        self.matherialPath = matherialPath
        self.$group.id = groupID
        self.$user.id = userID
        self.$subject.id = subjectID
    }
}

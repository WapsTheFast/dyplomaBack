//
//  LectureController.swift
//
//
//  Created by Андрэй Целігузаў on 29.04.23.
//

import Fluent
import Vapor

struct LectureController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let lectures = routes.grouped("api", "lectures")
    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let tokenAuthGroup = lectures.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    tokenAuthGroup.get(use: index)
    tokenAuthGroup.post(use: create)
    tokenAuthGroup.group(":lectureID") { lecture in
      lecture.delete(use: delete)
    }
    tokenAuthGroup.get(":groupID", use: getForGroup)
    tokenAuthGroup.get("forUser", use: getForUser)
    tokenAuthGroup.get("forStudent", use: getForStudent)
    tokenAuthGroup.get("checkStudents", ":lectureID", use: checkStudents)
    tokenAuthGroup.get("checkForStudent", use: checkForStudent)
    tokenAuthGroup.get("regenerate", ":lectureID", use: regenerateCode)
    tokenAuthGroup.get("one", ":lectureID", use: getOne)
    tokenAuthGroup.get("getStudentsForLecture", ":lectureID", use: getStudents)
    tokenAuthGroup.get("mark", ":code", use: markStudentOnLecture)

    tokenAuthGroup.put(use: update)
  }

  func index(req: Request) async throws -> [Lecture] {
    try await Lecture.query(on: req.db).all()
  }

  func getOne(req: Request) async throws -> Lecture {
    guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else {
      throw Abort(.notFound)
    }
    return lecture
  }

  func create(req: Request) async throws -> Lecture {
    let lecture = try req.content.decode(Lecture.self)
    guard let group = try await Group.find(lecture.$group.id, on: req.db) else {
      throw Abort(.notAcceptable)
    }
    lecture.code = UUID()
    try await lecture.save(on: req.db)
    let users: [User] = try await group.$users.get(on: req.db)
    let students: [User] = users.filter { $0.role == .student }
    for student in students {
      let studentOnLecture = StudentsOnLecture(
        state: "notOnLecture", groupID: group.id!, lectureID: lecture.id!, userID: student.id!)
      try await studentOnLecture.save(on: req.db)
    }
    return lecture
  }

  func regenerateCode(req: Request) async throws -> Lecture {
    guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else {
      throw Abort(.notFound)
    }
    lecture.code = UUID()
    try await lecture.save(on: req.db)
    return lecture
  }

  func getForGroup(req: Request) async throws -> [Lecture] {
    let user = try req.auth.require(User.self)
    guard let group = try await Group.find(req.parameters.get("groupID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let lectures = try await Lecture.query(on: req.db)
      .filter(\.$user.$id == user.id!)
      .filter(\.$group.$id == group.id!).all()
    return lectures
  }

  func getForUser(req: Request) async throws -> [Lecture] {
    let user = try req.auth.require(User.self)
    let groups = try await user.$groups.get(on: req.db)
    var lectures: [Lecture] = []
    for group in groups {
      let lecturesToAdd = try await Lecture.query(on: req.db)
        .filter(\.$user.$id == user.id!)
        .filter(\.$group.$id == group.id!).all()
      lectures.append(contentsOf: lecturesToAdd)
    }
    return lectures
  }

  func getForStudent(req: Request) async throws -> [Lecture] {
    let user = try req.auth.require(User.self)
    let groups = try await user.$groups.get(on: req.db)
    var lectures: [Lecture] = []
    for group in groups {
      let lecturesToAdd = try await Lecture.query(on: req.db)
        .filter(\.$group.$id == group.id!).all()
      lectures.append(contentsOf: lecturesToAdd)
    }
    return lectures
  }

  func checkForStudent(req: Request) async throws -> [StudentsOnLecture] {
    let user = try req.auth.require(User.self)
    let studentOnLecture = try await StudentsOnLecture.query(on: req.db)
      .filter(\.$user.$id == user.id!)
      .all()
    return studentOnLecture
  }

  func checkStudents(req: Request) async throws -> [StudentsOnLecture] {
    guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let studentOnLecture = try await StudentsOnLecture.query(on: req.db)
      .filter(\.$lecture.$id == lecture.id!)
      .all()
    return studentOnLecture
  }

  func getStudents(req: Request) async throws -> [User] {
    guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else {
      throw Abort(.notFound)
    }

    let studentOnLecture = try await StudentsOnLecture.query(on: req.db)
      .filter(\.$lecture.$id == lecture.id!)
      .all()

    var students: [User] = []
    for student in studentOnLecture {
      if let user = try await User.find(student.$user.id, on: req.db) {
        students.append(user)
      }
    }

    return students
  }

  func markStudentOnLecture(req: Request) async throws -> StudentsOnLecture {
    let user = try req.auth.require(User.self)
    guard
      let lecture = try await Lecture.query(on: req.db)
        .filter(\.$code == req.parameters.get("code"))
        .first()
    else {
      throw Abort(.notFound)
    }
    guard
      let studentOnLecture = try await StudentsOnLecture.query(on: req.db)
        .filter(\.$lecture.$id == lecture.id!)
        .filter(\.$user.$id == user.id!)
        .first()
    else {
      throw Abort(.notFound)
    }
    if lecture.date.addingTimeInterval(600) < Date() {
      studentOnLecture.state = .late
    } else {
      studentOnLecture.state = .onLecture
    }
    try await studentOnLecture.save(on: req.db)
    return studentOnLecture
  }

  func update(req: Request) async throws -> Lecture {
    let lecture = try req.content.decode(Lecture.self)

    guard let oldLecture = try await Lecture.find(lecture.id, on: req.db) else {
      throw Abort(.notFound)
    }

    oldLecture.state = lecture.state
    oldLecture.name = lecture.name
    oldLecture.date = lecture.date

    // if let newSubject = try await Subject.find(lecture.subject.id, on: req.db){

    //         oldLecture.subject.id = newSubject.id
    //         oldLecture.subject.name = newSubject.name
    // }

    try await oldLecture.update(on: req.db)
    return oldLecture
  }

  func delete(req: Request) async throws -> HTTPStatus {
    guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await lecture.delete(on: req.db)
    return .noContent
  }
}

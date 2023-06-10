//
//  WebsiteController.swift
//
//
//  Created by Андрэй Целігузаў on 09.06.23.
//

import Fluent
import Foundation
import Vapor

struct WebsiteController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let authSessionRoutes = routes.grouped(User.sessionAuthenticator())

    authSessionRoutes.get("login", use: loginHandler)

    let credentialsAuthRoutes = authSessionRoutes.grouped(User.credentialsAuthenticator())

    credentialsAuthRoutes.post("login", use: loginPostHandler)
    authSessionRoutes.post("logout", use: logoutHandler)

    authSessionRoutes.get(use: indexHandler)

    let protectedRoutes = authSessionRoutes.grouped(User.redirectMiddleware(path: "/login"))

    protectedRoutes.get("answers", use: allAnswersHandler)
    protectedRoutes.get("answers", ":answersID", use: answersHandler)

    protectedRoutes.get("users", ":userID", use: userHandler)
    protectedRoutes.get("users", use: allUsersHandler)
    protectedRoutes.get("users", "create", use: createUserHandler)
    protectedRoutes.post("users", "create", use: createUserPostHandler)
    protectedRoutes.get("users", ":userID", "edit", use: editUserHandler)
    protectedRoutes.post("users", ":userID", "edit", use: editUserPostHandler)
    protectedRoutes.post("users", ":userID", "delete", use: deleteUserHandler)

    protectedRoutes.get("subjects", use: allSubjectsHandler)
    protectedRoutes.get("subjects", ":subjectID", use: subjectsHandler)
    protectedRoutes.get("subjects", "create", use: createSubjectHandler)
    protectedRoutes.post("subjects", "create", use: createSubjectPostHandler)
    protectedRoutes.get("subjects", ":subjectID", "edit", use: editSubjectHandler)
    protectedRoutes.post("subjects", ":subjectID", "edit", use: editSubjectPostHandler)
    protectedRoutes.post("subjects", ":subjectID", "delete", use: deleteSubjectHandler)

    protectedRoutes.get("lectures", ":lectureID", use: lecturesHandler)
    protectedRoutes.post("lectures", ":lectureID", "edit", use: editLecturePostHandler)
    protectedRoutes.post("lectures", ":lectureID", "delete", use: deleteLectureHandler)

    protectedRoutes.get("groups", ":groupID", use: groupHandler)
    protectedRoutes.get("groups", use: allGroupsHandler)
    protectedRoutes.get("groups", "create", use: createGroupHandler)
    protectedRoutes.post("groups", "create", use: createGroupPostHandler)
    protectedRoutes.get("groups", ":groupID", "edit", use: editGroupHandler)
    protectedRoutes.post("groups", ":groupID", "edit", use: editGroupPostHandler)
    protectedRoutes.post("groups", ":groupID", "delete", use: deleteGroupHandler)

    protectedRoutes.get("feedback", ":feedbackID", use: feedbackHandler)
    protectedRoutes.get("feedback", use: allFeedbackHandler)
    protectedRoutes.post("feedback", ":feedbackID", "delete", use: deleteFeedbackHandler)
  }

  func indexHandler(_ req: Request) async throws -> View {
    let userLoggedIn = req.auth.has(User.self)
    var users: [User] = []
    if userLoggedIn {
      users = try await User.query(on: req.db).all()
    }
    let context = IndexContext(title: "Главная страница", userLoggedIn: userLoggedIn, users: users)
    return try await req.view.render("index", context)
  }

  // MARK: Answers

  func allAnswersHandler(_ req: Request) async throws -> View {
    let answers = try await Answers.query(on: req.db).all()
    let context = AllAnswersContext(answers: answers)
    return try await req.view.render("allAnswers", context)
  }

  func answersHandler(_ req: Request) async throws -> View {
    guard let answers = try await Answers.find(req.parameters.get("answersID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let questions = try await answers.$questions.get(on: req.db)
    var answersOnTest : [AnswersOnTest] = []
    for answer in answers.answers.answers{
      if let question = questions.questions.questions.first(where: {$0.questionText == answer.key}){ 
      var selectedAnswers : [String] = []
      for index in answer.value{
        let answer = question.options[index]
        selectedAnswers.append(answer)
      }
      var correctAnswers : [String] = []
      for index in question.correctAnswersIndices{
        let answer = question.options[index]
        correctAnswers.append(answer)
      }

      let studentAnswer = AnswersOnTest(questionText: question.questionText, selectedAnswers: selectedAnswers.joined(separator: ", "), correctAnswers: correctAnswers.joined(separator: ", "))
      answersOnTest.append(studentAnswer)
    }}
    let context = AnswersContext(title: answers.name,answers: answersOnTest )
    return try await req.view.render("answers", context)
  }

  // MARK: Users

  func userHandler(_ req: Request) async throws -> View {
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
      throw Abort(.notFound)
    }

    let lectures = try await user.$lectures.get(on: req.db)
    let groups = try await user.$groups.get(on: req.db)
    let answers = try await user.$answers.get(on: req.db)

    let context = UserContext(
      title: user.username,
      user: user,
      lectures: lectures,
      groups: groups,
      answers: answers)
    return try await req.view.render("user", context)

  }

  func allUsersHandler(_ req: Request) async throws -> View {
    let users = try await User.query(on: req.db)
      .all()
    let context = AllUserContext(title: "Пользователи", users: users)
    return try await req.view.render("allUsers", context)
  }

  func createUserHandler(_ req: Request) async throws -> View {
    let token = [UInt8].random(count: 16).base64
    req.session.data["CSRF_TOKEN"] = token
    let groups = try await Group.query(on: req.db).all()
    let context = CreateUserContext(allGroups: groups, csrfToken: token)
    return try await req.view.render("createUser", context)
  }
  func createUserPostHandler(_ req: Request) async throws -> Response {
    let data = try req.content.decode(CreateUserFromData.self)

    let exceptedToken = req.session.data["CSRF_TOKEN"]
    req.session.data["CSRF_TOKEN"] = nil
    guard
      let csrfToken = data.csrfToken,
      exceptedToken == csrfToken
    else {
      throw Abort(.badRequest)
    }

    let user = User(
      name: data.name, surname: data.surname, role: String(describing: data.role),
      email: data.email, username: data.username, password: data.password)

    try await user.save(on: req.db)

      for group in data.newGroups{
      if let groupToAttach = try await Group.find(group , on: req.db){
        try await groupToAttach.$users.attach(user, on: req.db)
        try await groupToAttach.save(on: req.db)
      }
    }
    try await user.save(on: req.db)
    let redirect = req.redirect(to: "/users/\(user.id!)")
    return redirect
  }

  func editUserHandler(_ req: Request) async throws -> View {
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let userGroups = try await user.$groups.get(on: req.db)
    let allGroups = try await Group.query(on: req.db).all()
    let context = EditUserContext(user: user, allGroups: allGroups, userGroups: userGroups)
    return try await req.view.render("createUser", context)
  }

  func editUserPostHandler(_ req: Request) async throws -> Response {
    let updateData = try req.content.decode(CreateUserFromData.self)
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
      throw Abort(.notFound)
    }

    user.name = updateData.name
    user.surname = updateData.surname
    user.username = updateData.username
    user.email = updateData.email
    if !isEmptyString(updateData.password){
      user.password = try Bcrypt.hash(updateData.password)
    }
    user.role = updateData.role

    let currentGroups = try await user.$groups.get(on: req.db)
    var newGroups : [Group] = []
    for group in updateData.newGroups{
      if let newGroup = try await Group.find(group, on: req.db){
        newGroups.append(newGroup)
      }
    }
    let groupsToRemove = currentGroups.filter { group in
            !newGroups.contains { $0.id == group.id }
        }
    let groupsToAdd = newGroups.filter { group in
            !currentGroups.contains { $0.id == group.id }
        }

        for group in groupsToRemove {
        try await user.$groups.detach(group, on: req.db)
    }

    for group in groupsToAdd {
        try await user.$groups.attach(group, on: req.db)
    }

    try await user.save(on: req.db)
    let redirect = req.redirect(to: "/users/\(user.id!)")
    return redirect

  }

  func deleteUserHandler(_ req: Request) async throws -> Response {
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await user.delete(on: req.db)
    return req.redirect(to: "/")
  }

  // MARK: Subjects

  func subjectsHandler(_ req: Request) async throws -> View {
    guard let subject = try await Subject.find(req.parameters.get("subjectID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let lectures = try await subject.$lectures.get(on: req.db)
    let context = SubjectContext(title: subject.name, subject: subject, lectures: lectures)
    return try await req.view.render("subject", context)
  }

  func allSubjectsHandler(_ req: Request) async throws -> View {
    let subjects = try await Subject.query(on: req.db).all()
    let context = AllSubjectsContext(subjects: subjects)
    return try await req.view.render("allSubjects", context)
  }

  func createSubjectHandler(_ req: Request) async throws -> View {
    let token = [UInt8].random(count: 16).base64
    req.session.data["CSRF_TOKEN"] = token
    let context = CreateSubjectContext(csrfToken: token)
    return try await req.view.render("createSubject", context)
  }

  func createSubjectPostHandler(_ req: Request) async throws -> Response {
    let data = try req.content.decode(CreateSubjectFromData.self)

    let exceptedToken = req.session.data["CSRF_TOKEN"]
    req.session.data["CSRF_TOKEN"] = nil
    guard
      let csrfToken = data.csrfToken,
      exceptedToken == csrfToken
    else {
      throw Abort(.badRequest)
    }

    let subject = Subject(name: data.name)
    try await subject.save(on: req.db)
    let redirect = req.redirect(to: "/subjects/\(subject.id!)")
    return redirect
  }

  func editSubjectHandler(_ req: Request) async throws -> View {
    guard let subject = try await Subject.find(req.parameters.get("subjectID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let lectures = try await subject.$lectures.get(on: req.db)
    let context = EditSubjectContext(subject: subject, lectures: lectures)
    return try await req.view.render("createSubject", context)
  }

  func editSubjectPostHandler(_ req: Request) async throws -> Response {
    let updateData = try req.content.decode(CreateSubjectFromData.self)
    guard let subject = try await Subject.find(req.parameters.get("subjectID"), on: req.db) else {
      throw Abort(.notFound)
    }

    subject.name = updateData.name

    try await subject.save(on: req.db)
    let redirect = req.redirect(to: "/subjects/\(subject.id!)")
    return redirect
  }

  func deleteSubjectHandler(_ req: Request) async throws -> Response {
    guard let subject = try await Subject.find(req.parameters.get("subjectID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await subject.delete(on: req.db)
    return req.redirect(to: "/")
  }

  // MARK: Lectures

  func lecturesHandler(_ req: Request) async throws -> View {
    guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let context = LectureContext(title: lecture.name, lecture: lecture)
    return try await req.view.render("lecture", context)
  }

  func editLecturePostHandler(_ req: Request) async throws -> Response {
    guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else {
      throw Abort(.notFound)
    }
    lecture.state = .done
    try await lecture.save(on: req.db)
    let redirect = req.redirect(to: "/lectures/\(lecture.id!)")
    return redirect
  }

  func deleteLectureHandler(_ req: Request) async throws -> Response {
    guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await lecture.delete(on: req.db)
    return req.redirect(to: "/")
  }

// MARK: Login

  func loginHandler(_ req: Request) async throws -> View {
    let context: LoginContext
    if let error = req.query[Bool.self, at: "error"], error {
      context = LoginContext(loginError: true)
    } else {
      context = LoginContext()
    }
    return try await req.view.render("login", context)
  }

  func loginPostHandler(_ req: Request) async throws -> Response {
    let user = try req.auth.require(User.self)
    if user.role == .administrator {
      return req.redirect(to: "/")
    } else {
      let context = LoginContext(loginError: true)
      return try await req.view.render("login", context).encodeResponse(for: req)
    }
  }

  func logoutHandler(_ req: Request) async throws -> Response {
    req.auth.logout(User.self)
    return req.redirect(to: "/")
  }

// MARK: Groups

  func groupHandler(_ req: Request) async throws -> View {
    guard let group = try await Group.find(req.parameters.get("subjectID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let users = try await group.$users.get(on: req.db)
    let lectures = try await group.$lectures.get(on: req.db)
    let context = GroupContext(title: group.name, group: group, users: users, lectures: lectures)
    return try await req.view.render("group", context)
  }

  func allGroupsHandler(_ req: Request) async throws -> View {
    let groups = try await Group.query(on: req.db).all()
    let context = AllGroupsContext(groups: groups)
    return try await req.view.render("allGroups", context)
  }

  func createGroupHandler(_ req: Request) async throws -> View {
    let token = [UInt8].random(count: 16).base64
    req.session.data["CSRF_TOKEN"] = token
    let context = CreateGroupContext(csrfToken: token)
    return try await req.view.render("createGroup", context)
  }

  func createGroupPostHandler(_ req: Request) async throws -> Response {
    let data = try req.content.decode(CreateGroupFromData.self)

    let exceptedToken = req.session.data["CSRF_TOKEN"]
    req.session.data["CSRF_TOKEN"] = nil
    guard
      let csrfToken = data.csrfToken,
      exceptedToken == csrfToken
    else {
      throw Abort(.badRequest)
    }

    let group = Group(
      name: data.name, course: data.course, color: data.color, inviteCode: data.inviteCode)
    try await group.save(on: req.db)
    let redirect = req.redirect(to: "/groups/\(group.id!)")
    return redirect
  }

  func editGroupHandler(_ req: Request) async throws -> View {
    guard let group = try await Group.find(req.parameters.get("groupID"), on: req.db) else {
      throw Abort(.notFound)
    }
    //let lectures = try await group.$lectures.get(on: req.db)
    let context = EditGroupContext(group: group)
    return try await req.view.render("createGroup", context)
  }

  func editGroupPostHandler(_ req: Request) async throws -> Response {
    let updateData = try req.content.decode(CreateGroupFromData.self)
    guard let group = try await Group.find(req.parameters.get("groupID"), on: req.db) else {
      throw Abort(.notFound)
    }

    group.name = updateData.name
    group.course = updateData.course
    group.color = updateData.color
    group.inviteCode = updateData.inviteCode

    try await group.save(on: req.db)
    let redirect = req.redirect(to: "/groups/\(group.id!)")
    return redirect
  }

  func deleteGroupHandler(_ req: Request) async throws -> Response {
    guard let subject = try await Group.find(req.parameters.get("groupID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await subject.delete(on: req.db)
    return req.redirect(to: "/")
  }
  func feedbackHandler(_ req: Request) async throws -> View {
    guard let feedback = try await Feedback.find(req.parameters.get("feedbackID"), on: req.db)
    else {
      throw Abort(.notFound)
    }
    let user = try await feedback.$user.get(on: req.db)

    let context = FeedbackContext(title: "\(user.name) \(user.surname)", feedback: feedback)
    return try await req.view.render("feedback", context)
  }

// MARK: Feedback

  func allFeedbackHandler(_ req: Request) async throws -> View {
    let feedbacks = try await Feedback.query(on: req.db).all()
    var userFeedback : [UserFeedback] = []
    for feedback in feedbacks{
      let uf = UserFeedback(feedback: feedback, user: try await feedback.$user.get(on: req.db))
      userFeedback.append(uf)
    }
    let context = AllFeedbackContext(feedbacks: userFeedback)
    return try await req.view.render("allFeedbacks", context)
  }

  func deleteFeedbackHandler(_ req: Request) async throws -> Response {
    guard let subject = try await Feedback.find(req.parameters.get("feedbackID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await subject.delete(on: req.db)
    return req.redirect(to: "/feedback")
  }

}

func isEmptyString(_ string: String) -> Bool {
    let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedString.isEmpty
}


struct UserContext: Encodable {
  let title: String
  let user: User
  let lectures: [Lecture]
  let groups: [Group]
  let answers: [Answers]
  let roles: [Role] = [.student, .teacher, .administrator]
}

struct AllUserContext: Encodable {
  let title: String
  let users: [User]
}

struct LectureContext: Encodable {
  let title: String
  let lecture: Lecture
}

struct IndexContext: Encodable {
  let title: String
  let userLoggedIn: Bool
  let users: [User]
}

struct SubjectContext: Encodable {
  let title: String
  let subject: Subject
  let lectures: [Lecture]
}

struct AllSubjectsContext: Encodable {
  let title: String = "Предметы"
  let subjects: [Subject]
}

struct AllAnswersContext: Encodable {
  let title: String = "Ответы"
  let answers: [Answers]
}

struct AnswersContext: Encodable {
  let title: String
  let answers : [AnswersOnTest]
}

struct AnswersOnTest : Codable{
  let questionText : String
  let selectedAnswers : String
  let correctAnswers : String
}

struct CreateSubjectContext: Encodable {
  let title = "Создание предмета"
  let csrfToken: String
}

struct CreateSubjectFromData: Content {
  let name: String
  let lectures: [Lecture]?
  let csrfToken: String?
}

struct EditSubjectContext: Encodable {
  let title: String = "Изменение предмета"
  let subject: Subject
  let editing: Bool = true
  let lectures: [Lecture]
}

struct CreateUserContext: Encodable {
  let title = "Создание пользователя"

  let roles: [Role] = [.student, .teacher, .administrator]
  let allGroups : [Group]
  let csrfToken: String
}

struct CreateUserFromData: Content {
  let name: String
  let surname: String
  let username: String
  let email: String
  let password: String
  let role: Role
  let csrfToken: String?
  let newGroups : [UUID]
}

struct EditUserContext: Encodable {
  let title: String = "Изменение пользователя"
  let user: User
  let editing: Bool = true
  let allGroups : [Group]
  let roles: [Role] = [.student, .teacher, .administrator]
  //let lectures : [Lecture]
  let userGroups : [Group]
  //let questions : [Questions]
  //let answers : [Answers]
}

struct EditLectureContext: Encodable {
  let title: String = "Изменение статуса лекции"
  let lecture: Lecture
  let editing: Bool = true
}

struct LoginContext: Encodable {
  let title: String = "Вход"
  let loginError: Bool

  init(loginError: Bool = false) {
    self.loginError = loginError
  }
}

struct GroupContext: Encodable {
  let title: String
  let group: Group
  let users: [User]
  let lectures: [Lecture]
}

struct AllGroupsContext: Encodable {
  let title = "Группы"
  let groups: [Group]
}

struct CreateGroupContext: Encodable {
  let title = "Создание группы"
  let csrfToken: String
}

struct CreateGroupFromData: Content {
  let name: String
  let course: String
  let color: String?
  let inviteCode: Int?
  let csrfToken: String?
}

struct EditGroupContext: Encodable {
  let title: String = "Изменение группы"
  let group: Group
  let editing: Bool = true
}

struct FeedbackContext: Encodable {
  let title: String
  let feedback: Feedback
}

struct AllFeedbackContext: Encodable {
  let title = "Сообщения пользователей"
  let feedbacks: [UserFeedback]
}

struct UserFeedback : Codable{
  let feedback : Feedback
  let user : User
}
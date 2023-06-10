//
//  User.swift
//
//
//  Created by Андрэй Целігузаў on 24.04.23.
//

import Fluent
import Vapor

final class User: Model, Content {
  static let schema = "users"

  @ID(key: .id)
  var id: UUID?

  @Children(for: \.$user)
  var lectures: [Lecture]

  @Children(for: \.$user)
  var userOnLecture: [StudentsOnLecture]

  @Children(for: \.$user)
  var questions: [Questions]

  @Children(for: \.$user)
  var answers: [Answers]

  @Siblings(through: UserGroup.self, from: \.$user, to: \.$group)
  var groups: [Group]

  @Field(key: "name")
  var name: String

  @Field(key: "surname")
  var surname: String

  @Enum(key: "role")
  var role: Role

  @Field(key: "email")
  var email: String

  @Field(key: "username")
  var username: String

  @Field(key: "password")
  var password: String

  init() {}

  init(
    id: UUID? = nil, name: String, surname: String, role: String, email: String, username: String,
    password: String
  ) {
    self.id = id
    self.name = name
    self.surname = surname
    if role == "administrator" {
      self.role = .administrator
    } else if role == "teacher" {
      self.role = .teacher
    } else if role == "student" {
      self.role = .student
    }
    self.email = email
    self.username = username
    self.password = password
  }

  final class Public: Content {
    var id: UUID?
    var username: String
    var name: String
    var surname: String
    var email: String
    var role: Role

    init(id: UUID?, username: String, name: String, surname: String, email: String, role: Role) {
      self.id = id
      self.username = username
      self.name = name
      self.surname = surname
      self.email = email
      self.role = role
    }
  }

}

extension User {
  func convertToPublic() -> User.Public {
    return User.Public(
      id: id, username: username, name: name, surname: surname, email: email, role: role)
  }
}

extension EventLoopFuture where Value: User {

  func convertToPublic() -> EventLoopFuture<User.Public> {

    return self.map { user in

      return user.convertToPublic()
    }
  }
}

extension Collection where Element: User {

  func convertToPublic() -> [User.Public] {

    return self.map { $0.convertToPublic() }
  }
}

extension EventLoopFuture where Value == [User] {

  func convertToPublic() -> EventLoopFuture<[User.Public]> {

    return self.map { $0.convertToPublic() }
  }
}

extension User: ModelAuthenticatable {
  static let usernameKey = \User.$username

  static let passwordHashKey = \User.$password

  func verify(password: String) throws -> Bool {
    try Bcrypt.verify(password, created: self.password)
  }
}

extension User: ModelSessionAuthenticatable {}
extension User: ModelCredentialsAuthenticatable {}

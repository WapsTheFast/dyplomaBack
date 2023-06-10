//
//  Subject.swift
//
//
//  Created by Андрэй Целігузаў on 28.04.23.
//

import Fluent
import Vapor

final class Subject: Model, Content {
  static let schema = "subjects"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "name")
  var name: String

  @Children(for: \.$subject)
  var lectures: [Lecture]

  init() {}

  init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
  }
}

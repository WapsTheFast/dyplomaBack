import Fluent
import Vapor

func routes(_ app: Application) throws {
  app.get { req async throws in
    try await req.view.render("index", ["title": "Hello Vapor!"])
  }

  app.get("hello") { req async -> String in
    "Hello, world!"
  }

  try app.register(collection: UserController())
  try app.register(collection: GroupController())
  try app.register(collection: UserGroupPivotController())
  try app.register(collection: SubjectController())
  try app.register(collection: LectureController())
  try app.register(collection: StudentsOnLectureController())
  try app.register(collection: QuestionsController())
  try app.register(collection: AnswersController())
  try app.register(collection: FileManagerController())
  try app.register(collection: FeedbackController())
  try app.register(collection: WebsiteController())

}

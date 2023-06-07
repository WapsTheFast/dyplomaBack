//
//  AnswersController.swift
//  
//
//  Created by Андрэй Целігузаў on 29.04.23.
//

import Fluent
import Vapor


struct FileManagerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let directory = DirectoryConfiguration.detect().workingDirectory + "lectures/uploads/"
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        let uploads = routes.grouped("uploads")
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = uploads.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(":lectureID", use: uploadHandler)
        tokenAuthGroup.get(":filename", use: downloadHandler)
    }

    func uploadHandler(_ req: Request) async throws -> String {
        guard let lecture = try await Lecture.find(req.parameters.get("lectureID"), on: req.db) else{
            throw Abort(.notFound)
        }
        let file = try req.content.decode(File.self)
        let ext = file.filename.split(separator: ".").last
        guard let fileExt = ext else{
            throw Abort(.badRequest)
        }
        let filename = UUID().uuidString + "." + String(fileExt)
        let path = req.application.directory.workingDirectory + "lectures/uploads/" + filename
        try await req.fileio.writeFile(file.data, at: path)
        lecture.matherialPath = filename
        try await lecture.save(on: req.db)
        return filename
    }   

    func downloadHandler(_ req: Request) async throws -> Response {
        guard let fileName = req.parameters.get("filename") else {
            throw Abort(.badRequest)
        }

        let filePath = req.application.directory.workingDirectory + "lectures/uploads/" + fileName
        let response =  req.fileio.streamFile(at: filePath)
        return response
    }





    
}

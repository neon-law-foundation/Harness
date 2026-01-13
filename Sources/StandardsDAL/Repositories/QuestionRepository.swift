import Fluent
import Foundation
import Vapor

public struct QuestionRepository: Sendable {

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func find(id: Int32) async throws -> Question? {
        try await Question.find(id, on: database)
    }

    public func findByCode(_ code: String) async throws -> Question? {
        try await Question.query(on: database)
            .filter(\.$code == code)
            .first()
    }

    public func findAll() async throws -> [Question] {
        try await Question.query(on: database).all()
    }

    public func findByType(_ questionType: QuestionType) async throws -> [Question] {
        try await Question.query(on: database)
            .filter(\.$questionType == questionType)
            .all()
    }

    public func create(model: Question) async throws -> Question {
        try await model.save(on: database)
        return model
    }

    public func update(model: Question) async throws -> Question {
        try await model.save(on: database)
        return model
    }

    public func delete(id: Int32) async throws {
        guard let question = try await find(id: id) else {
            throw RepositoryError.notFound
        }
        try await question.delete(on: database)
    }
}

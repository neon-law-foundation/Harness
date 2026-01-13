import Fluent
import Foundation
import Vapor

public struct PersonRepository: Sendable {

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func find(id: Int32) async throws -> Person? {
        try await Person.find(id, on: database)
    }

    public func findByEmail(_ email: String) async throws -> Person? {
        try await Person.query(on: database)
            .filter(\.$email == email)
            .first()
    }

    public func findAll() async throws -> [Person] {
        try await Person.query(on: database).all()
    }

    public func create(model: Person) async throws -> Person {
        try await model.save(on: database)
        return model
    }

    public func update(model: Person) async throws -> Person {
        try await model.save(on: database)
        return model
    }

    public func delete(id: Int32) async throws {
        guard let person = try await find(id: id) else {
            throw RepositoryError.notFound
        }
        try await person.delete(on: database)
    }
}

import Fluent
import Foundation
import Vapor

public struct UserRepository: Sendable {

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func find(id: Int32) async throws -> User? {
        try await User.find(id, on: database)
    }

    public func findBySub(_ sub: String) async throws -> User? {
        try await User.query(on: database)
            .filter(\.$sub == sub)
            .first()
    }

    public func findAll() async throws -> [User] {
        try await User.query(on: database).all()
    }

    public func create(model: User) async throws -> User {
        try await model.save(on: database)
        return model
    }

    public func update(model: User) async throws -> User {
        try await model.save(on: database)
        return model
    }

    public func delete(id: Int32) async throws {
        guard let user = try await find(id: id) else {
            throw RepositoryError.notFound
        }
        try await user.delete(on: database)
    }
}

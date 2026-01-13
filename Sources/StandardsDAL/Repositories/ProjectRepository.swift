import Fluent
import Foundation
import Vapor

public struct ProjectRepository: Sendable {

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func find(id: Int32) async throws -> Project? {
        try await Project.find(id, on: database)
    }

    public func findByCodename(_ codename: String) async throws -> Project? {
        try await Project.query(on: database)
            .filter(\.$codename == codename)
            .first()
    }

    public func findAll() async throws -> [Project] {
        try await Project.query(on: database).all()
    }

    public func create(model: Project) async throws -> Project {
        try await model.save(on: database)
        return model
    }

    public func update(model: Project) async throws -> Project {
        try await model.save(on: database)
        return model
    }

    public func delete(id: Int32) async throws {
        guard let project = try await find(id: id) else {
            throw RepositoryError.notFound
        }
        try await project.delete(on: database)
    }
}

import Fluent
import Foundation
import Vapor

public struct PersonEntityRoleRepository: Sendable {

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func find(id: Int32) async throws -> PersonEntityRole? {
        try await PersonEntityRole.find(id, on: database)
    }

    public func findAll() async throws -> [PersonEntityRole] {
        try await PersonEntityRole.query(on: database).all()
    }

    public func findByPerson(personId: Int32) async throws -> [PersonEntityRole] {
        try await PersonEntityRole.query(on: database)
            .filter(\.$person.$id == personId)
            .all()
    }

    public func findByEntity(entityId: Int32) async throws -> [PersonEntityRole] {
        try await PersonEntityRole.query(on: database)
            .filter(\.$entity.$id == entityId)
            .all()
    }

    public func findByRole(_ role: PersonEntityRoleType) async throws -> [PersonEntityRole] {
        try await PersonEntityRole.query(on: database)
            .filter(\.$role == role)
            .all()
    }

    public func create(model: PersonEntityRole) async throws -> PersonEntityRole {
        try await model.save(on: database)
        return model
    }

    public func update(model: PersonEntityRole) async throws -> PersonEntityRole {
        try await model.save(on: database)
        return model
    }

    public func delete(id: Int32) async throws {
        guard let role = try await find(id: id) else {
            throw RepositoryError.notFound
        }
        try await role.delete(on: database)
    }
}

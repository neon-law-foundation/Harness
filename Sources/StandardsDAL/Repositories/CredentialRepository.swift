import Fluent
import Foundation
import Vapor

public struct CredentialRepository: Sendable {

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func find(id: Int32) async throws -> Credential? {
        try await Credential.find(id, on: database)
    }

    public func findAll() async throws -> [Credential] {
        try await Credential.query(on: database).all()
    }

    public func findByPerson(personId: Int32) async throws -> [Credential] {
        try await Credential.query(on: database)
            .filter(\.$person.$id == personId)
            .all()
    }

    public func findByJurisdiction(jurisdictionId: Int32) async throws -> [Credential] {
        try await Credential.query(on: database)
            .filter(\.$jurisdiction.$id == jurisdictionId)
            .all()
    }

    public func create(model: Credential) async throws -> Credential {
        try await model.save(on: database)
        return model
    }

    public func update(model: Credential) async throws -> Credential {
        try await model.save(on: database)
        return model
    }

    public func delete(id: Int32) async throws {
        guard let credential = try await find(id: id) else {
            throw RepositoryError.notFound
        }
        try await credential.delete(on: database)
    }
}

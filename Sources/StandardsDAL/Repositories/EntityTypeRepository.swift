import Fluent
import Foundation
import Vapor

public struct EntityTypeRepository: Sendable {

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func find(id: Int32) async throws -> EntityType? {
        try await EntityType.find(id, on: database)
    }

    public func findAll() async throws -> [EntityType] {
        try await EntityType.query(on: database).all()
    }

    public func findByJurisdiction(jurisdictionId: Int32) async throws -> [EntityType] {
        try await EntityType.query(on: database)
            .filter(\.$jurisdiction.$id == jurisdictionId)
            .all()
    }

    public func create(model: EntityType) async throws -> EntityType {
        try await model.save(on: database)
        return model
    }

    public func update(model: EntityType) async throws -> EntityType {
        try await model.save(on: database)
        return model
    }

    public func delete(id: Int32) async throws {
        guard let entityType = try await find(id: id) else {
            throw RepositoryError.notFound
        }
        try await entityType.delete(on: database)
    }
}

import Fluent
import Foundation
import Vapor

public struct EntityRepository: Sendable {

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func find(id: Int32) async throws -> Entity? {
        try await Entity.find(id, on: database)
    }

    public func findAll() async throws -> [Entity] {
        try await Entity.query(on: database).all()
    }

    public func findByType(legalEntityTypeId: Int32) async throws -> [Entity] {
        try await Entity.query(on: database)
            .filter(\.$legalEntityType.$id == legalEntityTypeId)
            .all()
    }

    public func create(model: Entity) async throws -> Entity {
        try await model.save(on: database)
        return model
    }

    public func update(model: Entity) async throws -> Entity {
        try await model.save(on: database)
        return model
    }

    public func delete(id: Int32) async throws {
        guard let entity = try await find(id: id) else {
            throw RepositoryError.notFound
        }
        try await entity.delete(on: database)
    }
}

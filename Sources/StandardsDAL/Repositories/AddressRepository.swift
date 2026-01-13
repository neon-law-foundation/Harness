import Fluent
import Foundation
import Vapor

public struct AddressRepository: Sendable {

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func find(id: Int32) async throws -> Address? {
        try await Address.find(id, on: database)
    }

    public func findAll() async throws -> [Address] {
        try await Address.query(on: database).all()
    }

    public func findByPerson(personId: Int32) async throws -> [Address] {
        try await Address.query(on: database)
            .filter(\.$person.$id == personId)
            .all()
    }

    public func findByEntity(entityId: Int32) async throws -> [Address] {
        try await Address.query(on: database)
            .filter(\.$entity.$id == entityId)
            .all()
    }

    public func findVerified() async throws -> [Address] {
        try await Address.query(on: database)
            .filter(\.$isVerified == true)
            .all()
    }

    public func create(model: Address) async throws -> Address {
        try await model.save(on: database)
        return model
    }

    public func update(model: Address) async throws -> Address {
        try await model.save(on: database)
        return model
    }

    public func delete(id: Int32) async throws {
        guard let address = try await find(id: id) else {
            throw RepositoryError.notFound
        }
        try await address.delete(on: database)
    }
}

import Fluent
import Foundation
import Vapor

public struct MailboxRepository: Sendable {

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func find(id: Int32) async throws -> Mailbox? {
        try await Mailbox.find(id, on: database)
    }

    public func findAll() async throws -> [Mailbox] {
        try await Mailbox.query(on: database).all()
    }

    public func findByAddress(addressId: Int32) async throws -> [Mailbox] {
        try await Mailbox.query(on: database)
            .filter(\.$address.$id == addressId)
            .all()
    }

    public func findActive() async throws -> [Mailbox] {
        try await Mailbox.query(on: database)
            .filter(\.$isActive == true)
            .all()
    }

    public func create(model: Mailbox) async throws -> Mailbox {
        try await model.save(on: database)
        return model
    }

    public func update(model: Mailbox) async throws -> Mailbox {
        try await model.save(on: database)
        return model
    }

    public func delete(id: Int32) async throws {
        guard let mailbox = try await find(id: id) else {
            throw RepositoryError.notFound
        }
        try await mailbox.delete(on: database)
    }
}

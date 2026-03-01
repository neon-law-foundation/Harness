import FluentKit
import Foundation

public struct MailboxOfficeRepository: Sendable {

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func find(id: Int32) async throws -> MailboxOffice? {
        try await MailboxOffice.find(id, on: database)
    }

    public func findAll() async throws -> [MailboxOffice] {
        try await MailboxOffice.query(on: database).all()
    }

    public func findByEntity(entityId: Int32) async throws -> MailboxOffice? {
        try await MailboxOffice.query(on: database)
            .filter(\.$entity.$id == entityId)
            .first()
    }

    public func findActive() async throws -> [MailboxOffice] {
        try await MailboxOffice.query(on: database)
            .filter(\.$isActive == true)
            .all()
    }

    public func create(model: MailboxOffice) async throws -> MailboxOffice {
        try await model.save(on: database)
        return model
    }

    public func update(model: MailboxOffice) async throws -> MailboxOffice {
        try await model.save(on: database)
        return model
    }

    public func delete(id: Int32) async throws {
        guard let mailboxOffice = try await find(id: id) else {
            throw RepositoryError.notFound
        }
        try await mailboxOffice.delete(on: database)
    }
}

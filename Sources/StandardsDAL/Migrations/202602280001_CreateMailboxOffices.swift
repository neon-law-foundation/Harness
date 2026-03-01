import FluentKit

struct CreateMailboxOffices: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(MailboxOffice.schema)
            .field("id", .int32, .identifier(auto: true))
            .field("entity_id", .int32, .references("entities", "id"), .required)
            .field("is_active", .bool, .required)
            .field("inserted_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "entity_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(MailboxOffice.schema).delete()
    }
}

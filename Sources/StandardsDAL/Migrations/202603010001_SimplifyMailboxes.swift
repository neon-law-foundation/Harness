import FluentKit

struct SimplifyMailboxes: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Mailbox.schema).delete()

        try await database.schema(Mailbox.schema)
            .field("id", .int32, .identifier(auto: true))
            .field("entity_id", .int32, .references("entities", "id"), .required)
            .field("address_id", .int32, .references("addresses", "id"), .required)
            .field("location", .string, .required)
            .field("inserted_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "entity_id", "address_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Mailbox.schema).delete()

        try await database.schema("mailbox_offices")
            .field("id", .int32, .identifier(auto: true))
            .field("entity_id", .int32, .references("entities", "id"), .required)
            .field("is_active", .bool, .required)
            .field("inserted_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "entity_id")
            .create()

        try await database.schema(Mailbox.schema)
            .field("id", .int32, .identifier(auto: true))
            .field("mailbox_office_id", .int32, .references("mailbox_offices", "id"), .required)
            .field("address_id", .int32, .references("addresses", "id"), .required)
            .field("inserted_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "mailbox_office_id", "address_id")
            .create()
    }
}

import FluentKit
import Foundation

// Represents a mailbox office operated by an entity
public final class MailboxOffice: Model, @unchecked Sendable {
    public static let schema = "mailbox_offices"

    @ID(custom: .id, generatedBy: .database)
    public var id: Int32?

    @Parent(key: "entity_id")
    public var entity: Entity

    @Field(key: "is_active")
    public var isActive: Bool

    @Timestamp(key: "inserted_at", on: .create)
    public var insertedAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    public init() {}
}

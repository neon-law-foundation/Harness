import FluentKit
import Foundation

public enum MailboxLocation: String, Codable, CaseIterable, Sendable {
    case reno = "reno"
}

public final class Mailbox: Model, @unchecked Sendable {
    public static let schema = "mailboxes"

    @ID(custom: .id, generatedBy: .database)
    public var id: Int32?

    @Parent(key: "entity_id")
    public var entity: Entity

    @Parent(key: "address_id")
    public var address: Address

    @Field(key: "location")
    public var location: MailboxLocation

    @Timestamp(key: "inserted_at", on: .create)
    public var insertedAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    public init() {}
}

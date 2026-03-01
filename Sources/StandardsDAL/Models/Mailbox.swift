import FluentKit
import Foundation

// Represents a mailbox linking a mailbox office to an address
public final class Mailbox: Model, @unchecked Sendable {
    public static let schema = "mailboxes"

    @ID(custom: .id, generatedBy: .database)
    public var id: Int32?

    @Parent(key: "mailbox_office_id")
    public var mailboxOffice: MailboxOffice

    @Parent(key: "address_id")
    public var address: Address

    @Timestamp(key: "inserted_at", on: .create)
    public var insertedAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    public init() {}
}

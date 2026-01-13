import Fluent
import Foundation
import Vapor

/// Represents a mailbox at a physical address in the mail schema.
///
/// The `Mailbox` model stores mailbox information that is linked to specific physical
/// addresses in the directory system. Each mailbox has a unique number at its address
/// and can be activated or deactivated for mail receiving.
public final class Mailbox: Model, @unchecked Sendable {
    public static let schema = "mailboxes"

    @ID(custom: .id, generatedBy: .database)
    public var id: Int32?

    @Parent(key: "address_id")
    public var address: Address

    @Field(key: "mailbox_number")
    public var mailboxNumber: Int

    @Field(key: "is_active")
    public var isActive: Bool

    @Timestamp(key: "inserted_at", on: .create)
    public var insertedAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    public init() {}
}

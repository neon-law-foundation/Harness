import FluentKit
import SQLKit

/// Renames the `waiting_for_flow` and `waiting_for_alignment` enum values
/// in `assigned_notation_state` to `waiting_for_questionnaire` and
/// `waiting_for_workflow`.
///
/// PostgreSQL does not support renaming enum values directly. The approach is:
/// 1. Add the new values to the existing enum type.
/// 2. Migrate all existing rows that use the old values to the new ones.
/// 3. Leave the old values in the enum type — PostgreSQL does not allow
///    removing enum values without recreating the type, and doing so safely
///    would require schema locking that is out of scope for this migration.
///
/// For SQLite the enum is stored as TEXT, so only the data-update step is needed.
struct RenameAssignedNotationStateValues: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? SQLDatabase else { return }

        // Detect PostgreSQL by attempting a PG-only statement.
        // On SQLite this block is skipped and we fall through to the UPDATE.
        let isPostgres: Bool
        do {
            try await sql.raw(
                "ALTER TYPE assigned_notation_state ADD VALUE IF NOT EXISTS 'waiting_for_questionnaire'"
            ).run()
            try await sql.raw(
                "ALTER TYPE assigned_notation_state ADD VALUE IF NOT EXISTS 'waiting_for_workflow'"
            ).run()
            isPostgres = true
        } catch {
            // SQLite — enum type does not exist; TEXT values are unrestricted.
            isPostgres = false
        }

        // Migrate existing data.
        try await sql.raw(
            "UPDATE assigned_notations SET state = 'waiting_for_questionnaire' WHERE state = 'waiting_for_flow'"
        ).run()
        try await sql.raw(
            "UPDATE assigned_notations SET state = 'waiting_for_workflow' WHERE state = 'waiting_for_alignment'"
        ).run()

        _ = isPostgres  // suppress unused-variable warning
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? SQLDatabase else { return }
        try await sql.raw(
            "UPDATE assigned_notations SET state = 'waiting_for_flow' WHERE state = 'waiting_for_questionnaire'"
        ).run()
        try await sql.raw(
            "UPDATE assigned_notations SET state = 'waiting_for_alignment' WHERE state = 'waiting_for_workflow'"
        ).run()
    }
}

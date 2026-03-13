import FluentKit
import SQLKit

/// Renames tables and columns to align with the Template/Notation naming convention.
///
/// The old `notations` table stored reusable document definitions (now called templates).
/// The old `assigned_notations` table stored formal records placed on a respondent (now
/// called notations, reflecting the legal concept of a notation on a party's file).
///
/// Changes:
/// - `notations` → `templates`
/// - `assigned_notations` → `notations`
/// - `notations.notation_id` → `notations.template_id`
struct RenameNotationTables: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? SQLDatabase else { return }
        try await sql.raw("ALTER TABLE notations RENAME TO templates").run()
        try await sql.raw("ALTER TABLE assigned_notations RENAME TO notations").run()
        try await sql.raw("ALTER TABLE notations RENAME COLUMN notation_id TO template_id").run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? SQLDatabase else { return }
        try await sql.raw("ALTER TABLE notations RENAME COLUMN template_id TO notation_id").run()
        try await sql.raw("ALTER TABLE notations RENAME TO assigned_notations").run()
        try await sql.raw("ALTER TABLE templates RENAME TO notations").run()
    }
}

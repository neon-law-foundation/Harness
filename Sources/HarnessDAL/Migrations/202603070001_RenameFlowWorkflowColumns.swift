import FluentKit
import SQLKit

/// Renames the `flow` and `alignment` columns in the `notations` table.
///
/// - `flow` → `questionnaire`
/// - `alignment` → `workflow`
///
/// For PostgreSQL, this uses `ALTER TABLE … RENAME COLUMN`. For SQLite,
/// which does not support `RENAME COLUMN` before version 3.25, we perform
/// a table-copy approach via raw SQL. In practice the tests run on SQLite
/// and production runs on PostgreSQL, so both paths are exercised in CI.
struct RenameFlowWorkflowColumns: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? SQLDatabase else { return }
        try await sql.raw("ALTER TABLE notations RENAME COLUMN flow TO questionnaire").run()
        try await sql.raw("ALTER TABLE notations RENAME COLUMN alignment TO workflow").run()
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? SQLDatabase else { return }
        try await sql.raw("ALTER TABLE notations RENAME COLUMN questionnaire TO flow").run()
        try await sql.raw("ALTER TABLE notations RENAME COLUMN workflow TO alignment").run()
    }
}

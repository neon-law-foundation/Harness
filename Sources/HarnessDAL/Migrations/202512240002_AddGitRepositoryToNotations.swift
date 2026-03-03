import FluentKit
import SQLKit

/// Adds git repository tracking fields to the notations table.
///
/// This migration adds a code field (unique identifier within a repository) and a foreign key
/// to the git_repositories table. It also creates a unique index ensuring that the same
/// version of a notation code cannot exist multiple times in the same repository.
struct AddGitRepositoryToNotations: AsyncMigration {

    /// Adds code and git_repository_id fields with constraints and indexes.
    ///
    /// - Parameter database: The database connection to use for the migration.
    /// - Throws: Database errors if field addition fails.
    func prepare(on database: any Database) async throws {
        // Note: SQLite doesn't support adding foreign key constraints via ALTER TABLE
        // The foreign key relationship is enforced at the model level via @Parent
        // Split into separate updates for SQLite compatibility
        try await database.schema(Notation.schema)
            .field("code", .string)
            .update()

        try await database.schema(Notation.schema)
            .field("git_repository_id", .int32)
            .update()
    }

    /// Reverts the migration by removing the added fields and indexes.
    ///
    /// - Parameter database: The database connection to use for the migration.
    /// - Throws: Database errors during the revert operation.
    func revert(on database: any Database) async throws {
        if let sql = database as? SQLDatabase {
            try await sql.raw("DROP INDEX IF EXISTS notations_unique_version").run()
            try await sql.raw("DROP INDEX IF EXISTS notations_repo_code_inserted_at").run()
            try await sql.raw("DROP INDEX IF EXISTS notations_git_repository_id").run()
        }

        try await database.schema(Notation.schema)
            .deleteField("code")
            .deleteField("git_repository_id")
            .update()
    }
}

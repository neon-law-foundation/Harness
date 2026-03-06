import FluentKit

struct AddUniqueTitlePerRepository: AsyncMigration {
    func prepare(on database: any Database) async throws {
        do {
            try await database.schema(Notation.schema)
                .unique(on: "title", "git_repository_id")
                .update()
        } catch {
            // SQLite does not support adding constraints via ALTER TABLE.
            // The application-level check in NotationService enforces this
            // invariant for SQLite (used in tests).
        }
    }

    func revert(on database: any Database) async throws {
        do {
            try await database.schema(Notation.schema)
                .deleteUnique(on: "title", "git_repository_id")
                .update()
        } catch {
            // SQLite: no-op
        }
    }
}

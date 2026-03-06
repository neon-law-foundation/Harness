import FluentKit

struct AddUniqueTitlePerRepository: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Notation.schema)
            .unique(on: "title", "git_repository_id")
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Notation.schema)
            .deleteUnique(on: "title", "git_repository_id")
            .update()
    }
}

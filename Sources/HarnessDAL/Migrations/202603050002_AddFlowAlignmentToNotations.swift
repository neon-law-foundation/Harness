import FluentKit

struct AddFlowAlignmentToNotations: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Notation.schema)
            .field("flow", .json, .required)
            .update()
        try await database.schema(Notation.schema)
            .field("alignment", .json, .required)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Notation.schema)
            .deleteField("flow")
            .update()
        try await database.schema(Notation.schema)
            .deleteField("alignment")
            .update()
    }
}

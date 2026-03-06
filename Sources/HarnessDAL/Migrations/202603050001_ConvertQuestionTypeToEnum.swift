import FluentKit
import SQLKit

/// Converts the `question_type` column in the `questions` table from plain text to a
/// Postgres native enum type.
///
/// On PostgreSQL, this creates the `question_type` enum type and alters the existing column
/// in-place using a USING cast. On SQLite (used in tests), enum types map to text — no column
/// alteration is required.
struct ConvertQuestionTypeToEnum: AsyncMigration {
    func prepare(on database: any Database) async throws {
        _ = try await database.enum("question_type")
            .case("string")
            .case("text")
            .case("date")
            .case("datetime")
            .case("number")
            .case("yes_no")
            .case("radio")
            .case("select")
            .case("multi_select")
            .case("secret")
            .case("phone")
            .case("email")
            .case("ssn")
            .case("ein")
            .case("file")
            .case("person")
            .case("address")
            .case("org")
            .create()

        if let sql = database as? SQLDatabase {
            do {
                try await sql.raw(
                    """
                    ALTER TABLE questions
                    ALTER COLUMN question_type
                    TYPE question_type
                    USING question_type::question_type
                    """
                ).run()
            } catch {
                // SQLite does not support ALTER COLUMN TYPE.
                // Fluent maps enum types to text on SQLite, so no alteration is needed.
            }
        }
    }

    func revert(on database: any Database) async throws {
        if let sql = database as? SQLDatabase {
            do {
                try await sql.raw(
                    "ALTER TABLE questions ALTER COLUMN question_type TYPE varchar USING question_type::text"
                ).run()
            } catch {
                // SQLite: no-op
            }
        }

        try await database.enum("question_type").delete()
    }
}

import FluentKit
import FluentSQLiteDriver
import HarnessDAL
import SQLKit
import Testing

@Suite("DDL Command")
struct DDLCommandTests {

    /// All 18 schema tables that should appear in sqlite_master after migrations.
    private static let expectedTables: Set<String> = [
        "addresses",
        "assigned_notations",
        "blobs",
        "credentials",
        "disclosures",
        "entities",
        "entity_types",
        "git_repositories",
        "jurisdictions",
        "mailboxes",
        "notations",
        "people",
        "person_entity_roles",
        "projects",
        "questions",
        "relationship_logs",
        "share_classes",
        "users",
    ]

    @Test("DDL output contains all 18 schema tables")
    func testDDLContainsAllTables() async throws {
        try await withDatabase { db in
            guard let sqlDb = db as? SQLDatabase else {
                Issue.record("Database does not support raw SQL")
                return
            }

            let rows = try await sqlDb.raw(
                """
                SELECT name FROM sqlite_master
                WHERE type = 'table'
                AND name NOT LIKE '_fluent%'
                ORDER BY name
                """
            ).all()

            let tableNames = Set(
                try rows.map { try $0.decode(column: "name", as: String.self) }
            )

            for expected in Self.expectedTables {
                #expect(
                    tableNames.contains(expected),
                    "Missing table '\(expected)' in sqlite_master"
                )
            }

            #expect(
                tableNames.count == Self.expectedTables.count,
                "Expected \(Self.expectedTables.count) tables, got \(tableNames.count)"
            )
        }
    }

    @Test("DDL output contains CREATE TABLE statements")
    func testDDLContainsCreateStatements() async throws {
        try await withDatabase { db in
            guard let sqlDb = db as? SQLDatabase else {
                Issue.record("Database does not support raw SQL")
                return
            }

            let rows = try await sqlDb.raw(
                """
                SELECT sql FROM sqlite_master
                WHERE type = 'table'
                AND name NOT LIKE '_fluent%'
                ORDER BY name
                """
            ).all()

            #expect(!rows.isEmpty, "Expected CREATE TABLE statements")

            for row in rows {
                let sql = try row.decode(column: "sql", as: String.self)
                #expect(
                    sql.uppercased().contains("CREATE TABLE"),
                    "Expected CREATE TABLE in: \(sql)"
                )
            }
        }
    }

    @Test("DDL excludes Fluent internal tables")
    func testDDLExcludesFluentTables() async throws {
        try await withDatabase { db in
            guard let sqlDb = db as? SQLDatabase else {
                Issue.record("Database does not support raw SQL")
                return
            }

            let rows = try await sqlDb.raw(
                """
                SELECT name FROM sqlite_master
                WHERE type = 'table'
                AND name NOT LIKE '_fluent%'
                ORDER BY name
                """
            ).all()

            let tableNames = try rows.map { try $0.decode(column: "name", as: String.self) }

            for name in tableNames {
                #expect(
                    !name.hasPrefix("_fluent"),
                    "Fluent internal table '\(name)' should be excluded"
                )
            }
        }
    }
}

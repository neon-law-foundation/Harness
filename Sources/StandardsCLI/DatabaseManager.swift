#if os(macOS)
import Fluent
import FluentSQLiteDriver
import Foundation
import Logging
import StandardsDAL
import Vapor

/// Manages in-memory SQLite database for the CLI
public actor DatabaseManager {
    private let app: Application
    private let logger: Logger

    public init(seed: Bool = false) async throws {
        var silentLogger = Logger(label: "standards-cli")
        silentLogger.logLevel = .error
        self.logger = silentLogger

        var env = Environment(name: "testing", arguments: ["vapor"])
        try LoggingSystem.bootstrap(from: &env)

        self.app = try await Application.make(env)

        app.databases.use(.sqlite(.memory), as: .sqlite)
        app.logger = logger

        for migration in StandardsDALConfiguration.migrations {
            app.migrations.add(migration)
        }
        try await app.autoMigrate()

        if seed {
            _ = try await StandardsDALConfiguration.runSeeds(on: app.db, logger: logger)
        }
    }

    nonisolated public func getDatabase() -> Database {
        app.db
    }

    public func shutdown() async throws {
        try await app.asyncShutdown()
    }
}
#endif

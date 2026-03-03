import FluentKit
import FluentSQLiteDriver
import Foundation
import HarnessDAL
import Logging
import NIOPosix

/// Manages in-memory SQLite database for the CLI
public actor DatabaseManager {
    private let databases: Databases
    private let logger: Logger

    public init(seed: Bool = false) async throws {
        var silentLogger = Logger(label: "standards-cli")
        silentLogger.logLevel = .error
        self.logger = silentLogger

        let databases = Databases(
            threadPool: NIOThreadPool.singleton,
            on: MultiThreadedEventLoopGroup.singleton
        )
        databases.use(.sqlite(.memory), as: .sqlite)
        self.databases = databases

        let migrations = Migrations()
        for migration in HarnessDALConfiguration.migrations {
            migrations.add(migration)
        }

        let migrator = Migrator(
            databases: databases,
            migrations: migrations,
            logger: silentLogger,
            on: MultiThreadedEventLoopGroup.singleton.any()
        )
        try await migrator.setupIfNeeded().get()
        try await migrator.prepareBatch().get()

        if seed {
            guard
                let db = databases.database(
                    .sqlite,
                    logger: silentLogger,
                    on: MultiThreadedEventLoopGroup.singleton.any()
                )
            else {
                throw DatabaseManagerError.databaseUnavailable
            }
            _ = try await HarnessDALConfiguration.runSeeds(on: db, logger: silentLogger)
        }
    }

    public func getDatabase() -> any Database {
        databases.database(
            .sqlite,
            logger: logger,
            on: MultiThreadedEventLoopGroup.singleton.any()
        )!
    }

    public func shutdown() async throws {
        let dbs = databases
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                dbs.shutdown()
                continuation.resume()
            }
        }
    }
}

private enum DatabaseManagerError: Error {
    case databaseUnavailable
}

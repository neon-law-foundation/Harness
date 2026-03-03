import FluentKit
import FluentSQLiteDriver
import Foundation
import HarnessDAL
import Logging
import NIOPosix

private enum TestError: Error {
    case databaseUnavailable
}

/// Executes a test with a fresh migrated database and logger.
func withApplication<T>(
    _ operation: (any Database, Logger) async throws -> T
) async throws -> T {
    var logger = Logger(label: "harness-tests")
    logger.logLevel = .error

    let databases = Databases(
        threadPool: NIOThreadPool.singleton,
        on: MultiThreadedEventLoopGroup.singleton
    )
    databases.use(.sqlite(.memory), as: .sqlite)

    let migrations = Migrations()
    for migration in HarnessDALConfiguration.migrations {
        migrations.add(migration)
    }

    let migrator = Migrator(
        databases: databases,
        migrations: migrations,
        logger: logger,
        on: MultiThreadedEventLoopGroup.singleton.any()
    )
    try await migrator.setupIfNeeded().get()
    try await migrator.prepareBatch().get()

    guard
        let db = databases.database(
            .sqlite,
            logger: logger,
            on: MultiThreadedEventLoopGroup.singleton.any()
        )
    else {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                databases.shutdown()
                continuation.resume()
            }
        }
        throw TestError.databaseUnavailable
    }

    do {
        let result = try await operation(db, logger)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                databases.shutdown()
                continuation.resume()
            }
        }
        return result
    } catch {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                databases.shutdown()
                continuation.resume()
            }
        }
        throw error
    }
}

/// Executes a test with a fresh migrated database.
func withDatabase<T>(
    _ operation: (any Database) async throws -> T
) async throws -> T {
    try await withApplication { db, _ in try await operation(db) }
}

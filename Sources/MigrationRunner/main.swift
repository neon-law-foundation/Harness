import FluentKit
import FluentPostgresDriver
import FluentSQLiteDriver
import Foundation
import HarnessDAL
import Logging
import NIOPosix

var logger = Logger(label: "migration-runner")
logger.logLevel = .info

let action = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : (ProcessInfo.processInfo.environment["MIGRATION_ACTION"] ?? "migrate")

logger.info("Running migration action: \(action)")

let databases = Databases(
    threadPool: NIOThreadPool.singleton,
    on: MultiThreadedEventLoopGroup.singleton
)

let dbEnv = ProcessInfo.processInfo.environment["ENV"]?.lowercased() ?? "production"
let dbId: DatabaseID
if dbEnv == "production" {
    let hostname = ProcessInfo.processInfo.environment["DATABASE_HOST"] ?? "localhost"
    let port = Int(ProcessInfo.processInfo.environment["DATABASE_PORT"] ?? "5432") ?? 5432
    let username = ProcessInfo.processInfo.environment["DATABASE_USERNAME"] ?? "postgres"
    let password = ProcessInfo.processInfo.environment["DATABASE_PASSWORD"] ?? ""
    let database = ProcessInfo.processInfo.environment["DATABASE_NAME"] ?? "standards"
    let config = SQLPostgresConfiguration(
        hostname: hostname,
        port: port,
        username: username,
        password: password,
        database: database,
        tls: .disable
    )
    databases.use(.postgres(configuration: config), as: .psql)
    dbId = .psql
} else {
    databases.use(.sqlite(.memory), as: .sqlite)
    dbId = .sqlite
}

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

let shutdown = {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        DispatchQueue.global(qos: .userInitiated).async {
            databases.shutdown()
            continuation.resume()
        }
    }
}

guard
    let db = databases.database(
        dbId,
        logger: logger,
        on: MultiThreadedEventLoopGroup.singleton.any()
    )
else {
    await shutdown()
    logger.error("Failed to acquire database connection")
    exit(1)
}

switch action.lowercased() {
case "migrate":
    logger.info("Migrations applied: \(HarnessDALConfiguration.migrations.count)")

case "seed":
    let count = try await HarnessDALConfiguration.runSeeds(on: db, logger: logger)
    logger.info("Seeds loaded: \(count)")

case "both", "all":
    logger.info("Migrations applied: \(HarnessDALConfiguration.migrations.count)")
    let count = try await HarnessDALConfiguration.runSeeds(on: db, logger: logger)
    logger.info("Seeds loaded: \(count)")

default:
    await shutdown()
    logger.error("Invalid action '\(action)'. Use 'migrate', 'seed', or 'both'.")
    exit(1)
}

await shutdown()
logger.info("Migration runner completed successfully")

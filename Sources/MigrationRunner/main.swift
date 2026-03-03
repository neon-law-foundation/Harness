import AWSLambdaRuntime
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Foundation
import HarnessDAL
import Logging
import NIOPosix

struct MigrationRequest: Decodable {
    let action: String  // "migrate" or "seed" or "both"
}

struct MigrationResponse: Encodable {
    let success: Bool
    let message: String
    let migrationsRun: Int
    let seedsLoaded: Int
}

let runtime = LambdaRuntime {
    (
        event: MigrationRequest,
        context: LambdaContext
    ) async throws
        -> MigrationResponse in
    context.logger.info("Migration Lambda invoked with action: \(event.action)")

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
        logger: context.logger,
        on: MultiThreadedEventLoopGroup.singleton.any()
    )
    try await migrator.setupIfNeeded().get()
    try await migrator.prepareBatch().get()

    guard
        let db = databases.database(
            dbId,
            logger: context.logger,
            on: MultiThreadedEventLoopGroup.singleton.any()
        )
    else {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                databases.shutdown()
                continuation.resume()
            }
        }
        return MigrationResponse(
            success: false,
            message: "Failed to acquire database connection",
            migrationsRun: 0,
            seedsLoaded: 0
        )
    }

    var migrationsRun = 0
    var seedsLoaded = 0

    switch event.action.lowercased() {
    case "migrate":
        context.logger.info("Running migrations only")
        migrationsRun = HarnessDALConfiguration.migrations.count

    case "seed":
        context.logger.info("Running seeds only")
        seedsLoaded = try await HarnessDALConfiguration.runSeeds(
            on: db,
            logger: context.logger
        )

    case "both", "all":
        context.logger.info("Running migrations and seeds")
        migrationsRun = HarnessDALConfiguration.migrations.count
        seedsLoaded = try await HarnessDALConfiguration.runSeeds(
            on: db,
            logger: context.logger
        )

    default:
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                databases.shutdown()
                continuation.resume()
            }
        }
        return MigrationResponse(
            success: false,
            message: "Invalid action: \(event.action). Use 'migrate', 'seed', or 'both'",
            migrationsRun: 0,
            seedsLoaded: 0
        )
    }

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        DispatchQueue.global(qos: .userInitiated).async {
            databases.shutdown()
            continuation.resume()
        }
    }

    context.logger.info("Migration Lambda completed successfully")
    return MigrationResponse(
        success: true,
        message: "Migration completed successfully",
        migrationsRun: migrationsRun,
        seedsLoaded: seedsLoaded
    )
}

try await runtime.run()

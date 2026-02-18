import AWSLambdaRuntime
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Foundation
import Logging
import StandardsDAL
import Vapor

struct MigrationRequest: Decodable {
    let action: String  // "migrate" or "seed" or "both"
}

struct MigrationResponse: Encodable {
    let success: Bool
    let message: String
    let migrationsRun: Int
    let seedsLoaded: Int
}

let runtime = LambdaRuntime { (event: MigrationRequest, context: LambdaContext) async throws -> MigrationResponse in
    context.logger.info("Migration Lambda invoked with action: \(event.action)")

    // Create a temporary Vapor Application
    var vaporEnv = try Environment.detect()
    vaporEnv.arguments = ["serve"]

    let app = try await Application.make(vaporEnv)

    // Configure database
    let dbEnv = ProcessInfo.processInfo.environment["ENV"]?.lowercased() ?? "production"
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
        app.databases.use(DatabaseConfigurationFactory.postgres(configuration: config), as: .psql)
    } else {
        app.databases.use(DatabaseConfigurationFactory.sqlite(.memory), as: .sqlite)
    }
    for migration in StandardsDALConfiguration.migrations {
        app.migrations.add(migration)
    }
    try await app.autoMigrate()

    var migrationsRun = 0
    var seedsLoaded = 0

    switch event.action.lowercased() {
    case "migrate":
        context.logger.info("Running migrations only")
        migrationsRun = StandardsDALConfiguration.migrations.count

    case "seed":
        context.logger.info("Running seeds only")
        seedsLoaded = try await StandardsDALConfiguration.runSeeds(
            on: app.db,
            logger: context.logger
        )

    case "both", "all":
        context.logger.info("Running migrations and seeds")
        migrationsRun = StandardsDALConfiguration.migrations.count
        seedsLoaded = try await StandardsDALConfiguration.runSeeds(
            on: app.db,
            logger: context.logger
        )

    default:
        try await app.asyncShutdown()
        return MigrationResponse(
            success: false,
            message: "Invalid action: \(event.action). Use 'migrate', 'seed', or 'both'",
            migrationsRun: 0,
            seedsLoaded: 0
        )
    }

    try await app.asyncShutdown()

    context.logger.info("Migration Lambda completed successfully")
    return MigrationResponse(
        success: true,
        message: "Migration completed successfully",
        migrationsRun: migrationsRun,
        seedsLoaded: seedsLoaded
    )
}

try await runtime.run()

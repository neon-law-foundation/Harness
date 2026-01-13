import AWSLambdaRuntime
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
    var env = try Environment.detect()
    env.arguments = ["serve"]

    let app = try await Application.make(env)

    // Configure database using StandardsDAL
    try await StandardsDALConfiguration.configure(app)

    var migrationsRun = 0
    var seedsLoaded = 0

    switch event.action.lowercased() {
    case "migrate":
        context.logger.info("Running migrations only")
        // Migrations already run by configure()
        migrationsRun = 15  // Total number of migrations

    case "seed":
        context.logger.info("Running seeds only")
        seedsLoaded = try await StandardsDALConfiguration.runSeeds(
            on: app.db,
            environment: app.environment,
            logger: context.logger
        )

    case "both", "all":
        context.logger.info("Running migrations and seeds")
        // Migrations already run by configure()
        migrationsRun = 15
        seedsLoaded = try await StandardsDALConfiguration.runSeeds(
            on: app.db,
            environment: app.environment,
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

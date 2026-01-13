import Configuration
import Foundation
import Logging
import OpenAPIRuntime
import OpenAPIVapor
import StandardsDAL
import Vapor

/// Local development server for Standards API
///
/// Uses Swift Configuration to read the ENV environment variable.
/// Runs Vapor HTTP server for local development with Swagger UI.
@main
struct StandardsAPIServer {
    static func main() async throws {
        // Use Swift Configuration to verify environment
        let config = ConfigReader(provider: EnvironmentVariablesProvider())
        let environment = config.string(forKey: "env", default: "development")

        // Log the detected environment
        let logger = Logger(label: "com.sagebrush.standards.server")
        logger.info("Starting Standards API Server", metadata: ["environment": "\(environment)"])

        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)

        do {
            // Configure database (SQLite for local development)
            try await configureDatabase(app)

            // Configure routes
            try await configureRoutes(app)

            try await app.execute()
        } catch {
            app.logger.error("Failed to start server: \(error)")
            try? await app.asyncShutdown()
            throw error
        }
    }
}

/// Configure database connection for local development
private func configureDatabase(_ app: Application) async throws {
    // Configure database (uses SQLite for development)
    try await StandardsDALConfiguration.configure(app)

    // Load seed data
    let seedCount = try await StandardsDALConfiguration.runSeeds(
        on: app.db,
        environment: app.environment,
        logger: app.logger
    )

    app.logger.info("Loaded \(seedCount) seed records")
}

/// Configure routes and OpenAPI handlers
private func configureRoutes(_ app: Application) async throws {
    // Ensure Public directory exists
    let publicDirectory = app.directory.publicDirectory
    app.logger.info("Public directory: \(publicDirectory)")

    // Serve static files (Swagger UI)
    app.middleware.use(FileMiddleware(publicDirectory: publicDirectory))

    // Redirect root to Swagger UI
    app.get("") { req -> Response in
        req.redirect(to: "/index.html")
    }

    // Serve openapi.yaml at /openapi.yaml
    app.get("openapi.yaml") { req -> Response in
        let openapiPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("openapi.yaml")
            .path

        guard let yamlContent = try? String(contentsOfFile: openapiPath, encoding: .utf8) else {
            throw Abort(.notFound, reason: "OpenAPI specification not found")
        }

        return Response(
            status: .ok,
            headers: HTTPHeaders([("Content-Type", "application/yaml")]),
            body: Response.Body(string: yamlContent)
        )
    }

    // Create OpenAPI transport for Vapor
    let transport = VaporTransport(routesBuilder: app)

    // Create and register API handler
    let handler = StandardsAPIHandler(logger: app.logger)
    try handler.registerHandlers(on: transport, serverURL: Servers.Server1.url())

    app.logger.info("✅ Standards API server configured")
    app.logger.info("📚 Swagger UI available at http://localhost:8080")
    app.logger.info("📄 OpenAPI spec available at http://localhost:8080/openapi.yaml")
}

// MARK: - API Handler Implementation

/// Implementation of the Standards API service
struct StandardsAPIHandler: APIProtocol {
    let logger: Logger

    // MARK: - Health Check

    func getHealth(_ input: Operations.getHealth.Input) async throws -> Operations.getHealth
        .Output
    {
        logger.info("Health check requested")
        return .ok(
            .init(
                body: .json(
                    .init(
                        status: .healthy,
                        timestamp: Date()
                    )
                )
            )
        )
    }

    // MARK: - Persons

    func listPersons(_ input: Operations.listPersons.Input) async throws -> Operations
        .listPersons.Output
    {
        let page = input.query.page ?? 1
        let _ = input.query.limit ?? 20

        logger.info("Listing persons", metadata: ["page": "\(page)"])

        // TODO: Implement actual database query
        return .ok(
            .init(
                body: .json(
                    .init(
                        persons: [],
                        page: page,
                        totalPages: 0
                    )
                )
            )
        )
    }

    func createPerson(_ input: Operations.createPerson.Input) async throws -> Operations
        .createPerson.Output
    {
        guard case let .json(request) = input.body else {
            return .badRequest(
                .init(
                    body: .json(
                        .init(
                            error: "invalid_request",
                            message: "Request body must be JSON"
                        )
                    )
                )
            )
        }

        logger.info("Creating person", metadata: [
            "email": "\(request.email)",
            "name": "\(request.name)",
        ])

        // TODO: Implement actual database insertion
        let person = Components.Schemas.Person(
            id: UUID().uuidString,
            email: request.email,
            name: request.name,
            insertedAt: Date(),
            updatedAt: nil
        )

        return .created(
            .init(
                body: .json(person)
            )
        )
    }

    func getPerson(_ input: Operations.getPerson.Input) async throws -> Operations.getPerson
        .Output
    {
        let personId = input.path.personId
        logger.info("Getting person", metadata: ["personId": "\(personId)"])

        // TODO: Implement actual database query
        return .notFound(
            .init(
                body: .json(
                    .init(
                        error: "not_found",
                        message: "Person not found"
                    )
                )
            )
        )
    }

    func updatePerson(_ input: Operations.updatePerson.Input) async throws -> Operations
        .updatePerson.Output
    {
        let personId = input.path.personId
        guard case .json = input.body else {
            return .notFound(
                .init(
                    body: .json(
                        .init(
                            error: "invalid_request",
                            message: "Request body must be JSON"
                        )
                    )
                )
            )
        }

        logger.info("Updating person", metadata: ["personId": "\(personId)"])

        // TODO: Implement actual database update
        return .notFound(
            .init(
                body: .json(
                    .init(
                        error: "not_found",
                        message: "Person not found"
                    )
                )
            )
        )
    }

    // MARK: - Entities

    func listEntities(_ input: Operations.listEntities.Input) async throws -> Operations
        .listEntities.Output
    {
        let page = input.query.page ?? 1
        let _ = input.query.limit ?? 20

        logger.info("Listing entities", metadata: ["page": "\(page)"])

        return .ok(
            .init(
                body: .json(
                    .init(
                        entities: [],
                        page: page,
                        totalPages: 0
                    )
                )
            )
        )
    }

    func createEntity(_ input: Operations.createEntity.Input) async throws -> Operations
        .createEntity.Output
    {
        guard case let .json(request) = input.body else {
            return .badRequest(
                .init(
                    body: .json(
                        .init(
                            error: "invalid_request",
                            message: "Request body must be JSON"
                        )
                    )
                )
            )
        }

        logger.info("Creating entity", metadata: ["name": "\(request.name)"])

        let entity = Components.Schemas.Entity(
            id: UUID().uuidString,
            name: request.name,
            entityTypeId: request.entityTypeId,
            insertedAt: Date(),
            updatedAt: nil
        )

        return .created(
            .init(
                body: .json(entity)
            )
        )
    }

    func getEntity(_ input: Operations.getEntity.Input) async throws -> Operations.getEntity
        .Output
    {
        let entityId = input.path.entityId
        logger.info("Getting entity", metadata: ["entityId": "\(entityId)"])

        return .notFound(
            .init(
                body: .json(
                    .init(
                        error: "not_found",
                        message: "Entity not found"
                    )
                )
            )
        )
    }

    // MARK: - Credentials

    func listCredentials(_ input: Operations.listCredentials.Input) async throws -> Operations
        .listCredentials.Output
    {
        let page = input.query.page ?? 1
        let _ = input.query.limit ?? 20

        logger.info("Listing credentials", metadata: ["page": "\(page)"])

        return .ok(
            .init(
                body: .json(
                    .init(
                        credentials: [],
                        page: page,
                        totalPages: 0
                    )
                )
            )
        )
    }

    // MARK: - Jurisdictions

    func listJurisdictions(_ input: Operations.listJurisdictions.Input) async throws ->
        Operations.listJurisdictions.Output
    {
        logger.info("Listing jurisdictions")

        return .ok(
            .init(
                body: .json(
                    .init(jurisdictions: [])
                )
            )
        )
    }
}

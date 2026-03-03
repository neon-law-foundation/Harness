import Foundation
import HarnessDAL
import Logging
import OpenAPIRuntime

/// Shared implementation of the Standards API
///
/// This type implements all API endpoints and can be used with any transport
/// (Lambda, Vapor, etc.). It conforms to the `APIProtocol` generated from openapi.yaml.
struct HarnessAPIImplementation: APIProtocol {
    let logger: Logger

    init(logger: Logger = Logger(label: "com.harness.api")) {
        self.logger = logger
    }

    // MARK: - Health Check

    func getHealth(
        _ input: Operations.getHealth.Input
    ) async throws
        -> Operations.getHealth
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

    func listPersons(
        _ input: Operations.listPersons.Input
    ) async throws
        -> Operations
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

    func createPerson(
        _ input: Operations.createPerson.Input
    ) async throws
        -> Operations
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

        logger.info(
            "Creating person",
            metadata: [
                "email": "\(request.email)",
                "name": "\(request.name)",
            ]
        )

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

    func getPerson(
        _ input: Operations.getPerson.Input
    ) async throws
        -> Operations.getPerson
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

    func updatePerson(
        _ input: Operations.updatePerson.Input
    ) async throws
        -> Operations
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

    func listEntities(
        _ input: Operations.listEntities.Input
    ) async throws
        -> Operations
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

    func createEntity(
        _ input: Operations.createEntity.Input
    ) async throws
        -> Operations
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

    func getEntity(
        _ input: Operations.getEntity.Input
    ) async throws
        -> Operations.getEntity
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

    func listCredentials(
        _ input: Operations.listCredentials.Input
    ) async throws
        -> Operations
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

    func listJurisdictions(
        _ input: Operations.listJurisdictions.Input
    ) async throws -> Operations.listJurisdictions.Output {
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

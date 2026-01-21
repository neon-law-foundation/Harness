import Foundation
import Logging
import OpenAPILambda
import OpenAPIRuntime

/// Unified Standards API entry point
///
/// Reads the ENV environment variable and automatically chooses the appropriate
/// runtime (Vapor for local development, Lambda for production).
@main
struct StandardsAPI {
    static func main() async throws {
        let environment = ProcessInfo.processInfo.environment["env"] ?? "development"

        // Choose runtime based on ENV variable
        switch environment {
        case "production":
            try await runLambda()
        default:
            try await runVapor()
        }
    }
}

// MARK: - Lambda Runtime

/// Lambda-specific adapter for the Standards API
///
/// Wraps the shared `StandardsAPIImplementation` and integrates with
/// AWS Lambda Runtime via OpenAPILambda transport.
private struct LambdaAdapter: APIProtocol, OpenAPILambdaHttpApi {
    let implementation: StandardsAPIImplementation

    init() async throws {
        self.implementation = StandardsAPIImplementation()
    }

    func register(transport: OpenAPILambdaTransport) throws {
        try registerHandlers(on: transport)
    }

    // Forward all API methods to the shared implementation
    func getHealth(
        _ input: Operations.getHealth.Input
    ) async throws
        -> Operations.getHealth
        .Output
    {
        try await implementation.getHealth(input)
    }

    func listPersons(
        _ input: Operations.listPersons.Input
    ) async throws
        -> Operations
        .listPersons.Output
    {
        try await implementation.listPersons(input)
    }

    func createPerson(
        _ input: Operations.createPerson.Input
    ) async throws
        -> Operations
        .createPerson.Output
    {
        try await implementation.createPerson(input)
    }

    func getPerson(
        _ input: Operations.getPerson.Input
    ) async throws
        -> Operations.getPerson
        .Output
    {
        try await implementation.getPerson(input)
    }

    func updatePerson(
        _ input: Operations.updatePerson.Input
    ) async throws
        -> Operations
        .updatePerson.Output
    {
        try await implementation.updatePerson(input)
    }

    func listEntities(
        _ input: Operations.listEntities.Input
    ) async throws
        -> Operations
        .listEntities.Output
    {
        try await implementation.listEntities(input)
    }

    func createEntity(
        _ input: Operations.createEntity.Input
    ) async throws
        -> Operations
        .createEntity.Output
    {
        try await implementation.createEntity(input)
    }

    func getEntity(
        _ input: Operations.getEntity.Input
    ) async throws
        -> Operations.getEntity
        .Output
    {
        try await implementation.getEntity(input)
    }

    func listCredentials(
        _ input: Operations.listCredentials.Input
    ) async throws
        -> Operations
        .listCredentials.Output
    {
        try await implementation.listCredentials(input)
    }

    func listJurisdictions(
        _ input: Operations.listJurisdictions.Input
    ) async throws -> Operations.listJurisdictions.Output {
        try await implementation.listJurisdictions(input)
    }
}

/// Run the API using AWS Lambda Runtime
private func runLambda() async throws {
    let adapter = try await LambdaAdapter()
    try await adapter.run()
}

/// Run the API using Vapor HTTP server (local development)
private func runVapor() async throws {
    // Import Vapor dynamically only when needed
    // This keeps Lambda deployments lightweight
    fatalError(
        "Vapor runtime not available in StandardsAPI target. Use StandardsAPIServer instead."
    )
}

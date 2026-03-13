import FluentKit
import Foundation

/// Service responsible for creating and managing notations with version validation.
public actor NotationService {
    private let database: Database
    private let templateService: TemplateService

    public init(database: Database) {
        self.database = database
        self.templateService = TemplateService(database: database)
    }

    /// Creates a new notation after validating it uses the latest template version.
    ///
    /// Enforces the business rule that notations can only be created from the latest version
    /// of a template. If a newer version exists, the request is rejected with
    /// ``NotationError/outdatedVersion(requestedTemplateID:requestedVersion:requestedInsertedAt:latestTemplateID:latestVersion:latestInsertedAt:code:repositoryID:)``.
    ///
    /// - Parameters:
    ///   - templateID: The template to assign.
    ///   - personID: The person to assign to (if applicable).
    ///   - entityID: The entity to assign to (if applicable).
    ///   - state: The initial state for the notation (defaults to `.open`).
    /// - Returns: The created notation.
    /// - Throws: ``NotationError`` if validation fails.
    public func createNotation(
        templateID: Int32,
        personID: Int32?,
        entityID: Int32?,
        state: NotationState = .open
    ) async throws -> Notation {

        guard let template = try await Template.find(templateID, on: database) else {
            throw NotationError.templateNotFound(templateID)
        }

        try await template.$gitRepository.load(on: database)

        guard let gitRepo = template.gitRepository else {
            throw NotationError.templateNotFound(templateID)
        }
        let gitRepoID = try gitRepo.requireID()

        guard let code = template.code else {
            throw NotationError.templateNotFound(templateID)
        }

        guard
            let latestVersion = try await templateService.findLatestVersion(
                gitRepositoryID: gitRepoID,
                code: code
            )
        else {
            throw NotationError.noLatestVersionFound(
                repository: gitRepoID,
                code: code
            )
        }

        let latestTemplateID = try latestVersion.requireID()
        if latestTemplateID != templateID {
            throw NotationError.outdatedVersion(
                requestedTemplateID: templateID,
                requestedVersion: template.version,
                requestedInsertedAt: template.insertedAt!,
                latestTemplateID: latestTemplateID,
                latestVersion: latestVersion.version,
                latestInsertedAt: latestVersion.insertedAt!,
                code: code,
                repositoryID: gitRepoID
            )
        }

        let hasActive = try await Notation.hasActiveAssignment(
            templateID: templateID,
            personID: personID,
            entityID: entityID,
            on: database
        )

        if hasActive {
            throw NotationError.activeAssignmentExists(
                templateID: templateID,
                personID: personID,
                entityID: entityID
            )
        }

        let notation = Notation()
        notation.$template.id = templateID
        notation.$person.id = personID
        notation.$entity.id = entityID
        notation.state = state

        try await notation.validate(on: database)
        try await notation.save(on: database)

        return notation
    }

    /// Creates a notation using repository and code, automatically using the latest template version.
    ///
    /// This convenience method finds the latest version of a template by its repository and code,
    /// then creates a notation against it.
    ///
    /// - Parameters:
    ///   - gitRepositoryID: The ID of the git repository.
    ///   - code: The template code.
    ///   - personID: The person to assign to (if applicable).
    ///   - entityID: The entity to assign to (if applicable).
    ///   - state: The initial state for the notation (defaults to `.open`).
    /// - Returns: The created notation.
    /// - Throws: ``NotationError`` if no latest version is found or validation fails.
    public func createNotationByCode(
        gitRepositoryID: Int32,
        code: String,
        personID: Int32?,
        entityID: Int32?,
        state: NotationState = .open
    ) async throws -> Notation {
        guard
            let latestTemplate = try await templateService.findLatestVersion(
                gitRepositoryID: gitRepositoryID,
                code: code
            )
        else {
            throw NotationError.noLatestVersionFound(
                repository: gitRepositoryID,
                code: code
            )
        }

        return try await createNotation(
            templateID: try latestTemplate.requireID(),
            personID: personID,
            entityID: entityID,
            state: state
        )
    }
}

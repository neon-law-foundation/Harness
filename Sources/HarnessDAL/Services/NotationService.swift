import FluentKit
import Foundation

/// Service responsible for notation version management and validation.
public actor NotationService {
    private let database: Database
    private let validator = NotationValidator()

    public init(database: Database) {
        self.database = database
    }

    /// Finds the latest version of a notation by code across all repositories.
    ///
    /// - Parameter code: The notation code to look up.
    /// - Returns: The most recent notation with that code, or nil if none exists.
    public func findLatestByCode(_ code: String) async throws -> Notation? {
        let results = try await Notation.query(on: database)
            .sort(\.$insertedAt, .descending)
            .all()

        return results.first { $0.code == code }
    }

    /// Finds the latest version of each unique notation code across all repositories.
    ///
    /// Results are sorted by `insertedAt` descending, then deduplicated by `code`,
    /// so the most recent version of each notation is returned.
    ///
    /// - Returns: An array of the latest notation per unique code.
    public func findAllLatest() async throws -> [Notation] {
        let all = try await Notation.query(on: database)
            .sort(\.$insertedAt, .descending)
            .all()

        var seen = Set<String>()
        var result: [Notation] = []
        for notation in all {
            guard let code = notation.code else { continue }
            if !seen.contains(code) {
                seen.insert(code)
                result.append(notation)
            }
        }
        return result
    }

    /// Finds the latest version of a notation by repository and code.
    ///
    /// - Parameters:
    ///   - gitRepositoryID: The ID of the git repository.
    ///   - code: The notation code.
    /// - Returns: The most recent notation, or nil if none exists.
    public func findLatestVersion(
        gitRepositoryID: Int32,
        code: String
    ) async throws -> Notation? {
        let results = try await Notation.query(on: database)
            .filter(\.$gitRepository.$id == gitRepositoryID)
            .sort(\.$insertedAt, .descending)
            .all()

        return results.first { $0.code == code }
    }

    /// Finds all versions of a notation ordered by most recent first.
    ///
    /// - Parameters:
    ///   - gitRepositoryID: The ID of the git repository.
    ///   - code: The notation code.
    /// - Returns: An array of all versions of the notation.
    public func findAllVersions(
        gitRepositoryID: Int32,
        code: String
    ) async throws -> [Notation] {
        let results = try await Notation.query(on: database)
            .filter(\.$gitRepository.$id == gitRepositoryID)
            .sort(\.$insertedAt, .descending)
            .all()

        return results.filter { $0.code == code }
    }

    /// Creates a new notation version.
    ///
    /// Validates that this creates a newer version than existing ones.
    ///
    /// - Parameters:
    ///   - gitRepositoryID: The ID of the git repository.
    ///   - code: Unique code for this notation type.
    ///   - version: Git commit SHA.
    ///   - title: Display title.
    ///   - description: Brief description.
    ///   - respondentType: Who can be assigned this notation.
    ///   - markdownContent: The notation template content.
    ///   - frontmatter: Structured metadata.
    ///   - questionnaire: The questionnaire state machine map.
    ///   - workflow: The workflow state machine map.
    ///   - ownerID: Optional owner entity ID.
    /// - Returns: The created notation.
    /// - Throws: `NotationError` if version already exists.
    public func createVersion(
        gitRepositoryID: Int32,
        code: String,
        version: String,
        title: String,
        description: String,
        respondentType: RespondentType,
        markdownContent: String,
        frontmatter: [String: String],
        questionnaire: [String: [String: String]] = [:],
        workflow: [String: [String: String]] = [:],
        ownerID: Int32?
    ) async throws -> Notation {
        let allVersions = try await Notation.query(on: database)
            .filter(\.$gitRepository.$id == gitRepositoryID)
            .filter(\.$version == version)
            .all()

        if allVersions.contains(where: { $0.code == code }) {
            throw NotationError.versionAlreadyExists(
                repository: gitRepositoryID,
                code: code,
                version: version
            )
        }

        let existingWithTitle = try await Notation.query(on: database)
            .filter(\.$gitRepository.$id == gitRepositoryID)
            .filter(\.$title == title)
            .first()

        if existingWithTitle != nil {
            throw NotationError.titleAlreadyExists(title)
        }

        let notation = Notation()
        notation.$gitRepository.id = gitRepositoryID
        notation.code = code
        notation.version = version
        notation.title = title
        notation.description = description
        notation.respondentType = respondentType
        notation.markdownContent = markdownContent
        notation.frontmatter = frontmatter
        notation.questionnaire = questionnaire
        notation.workflow = workflow
        notation.$owner.id = ownerID

        try await notation.save(on: database)
        return notation
    }

    /// Creates a new notation version with validation.
    ///
    /// Validates all notation fields before saving to the database.
    ///
    /// - Parameters:
    ///   - gitRepositoryID: The ID of the git repository.
    ///   - code: Unique code for this notation type.
    ///   - version: Git commit SHA.
    ///   - title: Display title.
    ///   - description: Brief description.
    ///   - respondentType: Who can be assigned this notation.
    ///   - markdownContent: The notation template content.
    ///   - frontmatter: Structured metadata.
    ///   - questionnaire: The questionnaire state machine map.
    ///   - workflow: The workflow state machine map.
    ///   - ownerID: Optional owner entity ID.
    /// - Returns: The created notation.
    /// - Throws: `NotationError.validationFailed` if validation fails, or other `NotationError` types.
    public func createVersionWithValidation(
        gitRepositoryID: Int32,
        code: String,
        version: String,
        title: String,
        description: String,
        respondentType: RespondentType,
        markdownContent: String,
        frontmatter: [String: String],
        questionnaire: [String: [String: String]] = [:],
        workflow: [String: [String: String]] = [:],
        ownerID: Int32?
    ) async throws -> Notation {
        let validations = validator.validate(
            title: title,
            description: description,
            respondentType: respondentType.rawValue,
            frontmatter: frontmatter,
            markdownContent: markdownContent
        )

        if !validations.isEmpty {
            throw NotationError.validationFailed(validations)
        }

        return try await createVersion(
            gitRepositoryID: gitRepositoryID,
            code: code,
            version: version,
            title: title,
            description: description,
            respondentType: respondentType,
            markdownContent: markdownContent,
            frontmatter: frontmatter,
            questionnaire: questionnaire,
            workflow: workflow,
            ownerID: ownerID
        )
    }
}

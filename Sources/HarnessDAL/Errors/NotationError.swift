import Foundation

/// Errors related to notation operations and validation.
public enum NotationError: Error, LocalizedError {

    /// Template with specified ID not found.
    case templateNotFound(Int32)

    /// No latest version found for the specified template.
    case noLatestVersionFound(repository: Int32, code: String)

    /// Attempted to create a notation from an outdated template version.
    case outdatedVersion(
        requestedTemplateID: Int32,
        requestedVersion: String,
        requestedInsertedAt: Date,
        latestTemplateID: Int32,
        latestVersion: String,
        latestInsertedAt: Date,
        code: String,
        repositoryID: Int32
    )

    /// An active notation already exists for this template and respondents.
    case activeAssignmentExists(templateID: Int32, personID: Int32?, entityID: Int32?)

    /// Notation is invalid for the template's respondent type.
    case invalidAssignment(String)

    public var errorDescription: String? {
        switch self {
        case .templateNotFound(let id):
            return "Template with ID \(id) not found"
        case .noLatestVersionFound(let repo, let code):
            return "No versions found for template '\(code)' in repository \(repo)"
        case .outdatedVersion(
            let reqID,
            let reqVer,
            let reqDate,
            let latestID,
            let latestVer,
            let latestDate,
            let code,
            let repoID
        ):
            return """
                Cannot create notation from outdated template version.

                Requested: Template ID \(reqID), version '\(reqVer)', created \(reqDate)
                Latest: Template ID \(latestID), version '\(latestVer)', created \(latestDate)

                Please use the latest version of '\(code)' from repository \(repoID).
                """
        case .activeAssignmentExists(let templateID, let personID, let entityID):
            return
                "Active notation already exists for template \(templateID), person \(personID ?? 0), entity \(entityID ?? 0)"
        case .invalidAssignment(let reason):
            return "Invalid notation: \(reason)"
        }
    }
}

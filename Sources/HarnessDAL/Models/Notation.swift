import FluentKit
import Foundation

/// The lifecycle state of a notation.
///
/// A notation moves through states from initial assignment to completion.
/// The state machine ensures proper workflow orchestration and prevents
/// duplicate active notations for the same template and respondent.
///
/// ## State Transitions
///
/// ```
/// open → review → closed
///   ↓       ↓
///   ↓   waiting_for_workflow → review/closed
///   ↓
/// waiting_for_questionnaire → open/closed
/// ```
///
/// ## Topics
///
/// ### States
///
/// - ``open``
/// - ``review``
/// - ``waitingForQuestionnaire``
/// - ``waitingForWorkflow``
/// - ``closed``
public enum NotationState: String, Codable, CaseIterable, Sendable {

    /// The initial state when a template is first assigned to a respondent.
    ///
    /// The respondent needs to complete the template requirements.
    /// The notation remains active and prevents duplicate notations for the same
    /// template and respondent.
    ///
    /// ### Valid Transitions
    /// - ``review``: When the respondent submits their response
    /// - ``waitingForQuestionnaire``: When a dependency on another questionnaire is detected
    /// - ``waitingForWorkflow``: When workflow coordination is required
    /// - ``closed``: When auto-completion rules are met
    case open = "open"

    /// The state when a submitted response is awaiting review.
    ///
    /// A reviewer examines the respondent's submission to determine if it meets requirements.
    ///
    /// ### Valid Transitions
    /// - ``open``: When the reviewer requests changes from the respondent
    /// - ``waitingForWorkflow``: When the reviewer identifies workflow needs
    /// - ``closed``: When the reviewer approves the response
    case review = "review"

    /// The state when waiting for a dependent questionnaire to complete.
    ///
    /// The notation is blocked because it depends on another questionnaire to finish first.
    ///
    /// ### Valid Transitions
    /// - ``open``: When the blocking questionnaire completes and further action is needed
    /// - ``closed``: When the blocking questionnaire completes and auto-approval rules are met
    case waitingForQuestionnaire = "waiting_for_questionnaire"

    /// The state when waiting for workflow coordination with other parties.
    ///
    /// The notation requires input or agreement from related people or entities before proceeding.
    ///
    /// ### Valid Transitions
    /// - ``open``: When the workflow completes and the respondent needs to update their response
    /// - ``review``: When the workflow completes and the response needs review
    /// - ``closed``: When the workflow completes and auto-approval rules are met
    case waitingForWorkflow = "waiting_for_workflow"

    /// The final state when the notation is completed and finalized.
    ///
    /// The notation is no longer active. This allows new notations for the same template
    /// and respondent if needed. Closed notations are archived and cannot be reopened.
    case closed = "closed"
}

/// A formal record that a ``Template`` has been assigned to a specific respondent.
///
/// A `Notation` links a ``Template`` to a person, entity, or both, and tracks the
/// assignment through its lifecycle using a state machine. The term "notation" reflects
/// the legal concept of a formal record placed on a party's file.
///
/// The assignment enforces business rules based on the template's respondent type:
/// - For `.person` templates, only `person_id` must be set
/// - For `.entity` templates, only `entity_id` must be set
/// - For `.personAndEntity` templates, both IDs must be set
///
/// Database constraints prevent duplicate active notations to ensure only one notation
/// can be in an active state (not `closed`) for a given template and respondent combination.
///
/// ## Topics
///
/// ### Creating and Validating Notations
///
/// - ``init()``
/// - ``validate(on:)``
///
/// ### Checking Notation Status
///
/// - ``hasActiveAssignment(templateID:personID:entityID:on:)``
///
/// ### Properties
///
/// - ``id``
/// - ``template``
/// - ``person``
/// - ``entity``
/// - ``state``
/// - ``insertedAt``
/// - ``updatedAt``
public final class Notation: Model, @unchecked Sendable {
    public static let schema = "notations"

    /// The unique identifier for this notation.
    @ID(custom: .id, generatedBy: .database)
    public var id: Int32?

    /// The template this notation is based on.
    @Parent(key: "template_id")
    public var template: Template

    /// The person assigned to this notation, if applicable.
    ///
    /// Required when the template's respondent type is `.person` or `.personAndEntity`.
    /// Must be `nil` when the respondent type is `.entity`.
    @OptionalParent(key: "person_id")
    public var person: Person?

    /// The entity assigned to this notation, if applicable.
    ///
    /// Required when the template's respondent type is `.entity` or `.personAndEntity`.
    /// Must be `nil` when the respondent type is `.person`.
    @OptionalParent(key: "entity_id")
    public var entity: Entity?

    /// The current state of this notation in its lifecycle.
    ///
    /// See ``NotationState`` for valid states and transitions.
    @Enum(key: "state")
    public var state: NotationState

    /// The timestamp when this notation was created.
    @Timestamp(key: "inserted_at", on: .create)
    public var insertedAt: Date?

    /// The timestamp when this notation was last updated.
    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    /// Creates a new notation instance.
    public init() {}

    /// Validates that the notation has the correct person and entity IDs based on the template's respondent type.
    ///
    /// Enforces business rules by checking that the notation's person and entity IDs
    /// match the requirements of the template's respondent type:
    /// - `.person` requires `person_id` set and `entity_id` nil
    /// - `.entity` requires `entity_id` set and `person_id` nil
    /// - `.personAndEntity` requires both IDs set
    ///
    /// Call this method before saving a new notation to ensure data integrity.
    ///
    /// - Parameter database: The database connection to use for loading the template.
    /// - Throws: `NotationError.invalidAssignment` if the IDs don't match the respondent type requirements.
    public func validate(on database: Database) async throws {
        try await self.$template.load(on: database)

        let personID = self.$person.id
        let entityID = self.$entity.id

        switch self.template.respondentType {
        case .person:
            guard personID != nil && entityID == nil else {
                throw NotationError.invalidAssignment(
                    "For respondent type 'person', person_id must be set and entity_id must be nil"
                )
            }
        case .entity:
            guard entityID != nil && personID == nil else {
                throw NotationError.invalidAssignment(
                    "For respondent type 'entity', entity_id must be set and person_id must be nil"
                )
            }
        case .personAndEntity:
            guard personID != nil && entityID != nil else {
                throw NotationError.invalidAssignment(
                    "For respondent type 'person_and_entity', both person_id and entity_id must be set"
                )
            }
        }
    }

    /// Checks if an active notation already exists for the same template and respondent combination.
    ///
    /// A notation is considered active if its state is `.open`. Use this method before creating
    /// a new notation to provide better error messages than relying on database constraint violations.
    ///
    /// - Parameters:
    ///   - templateID: The ID of the template to check.
    ///   - personID: The person ID to check, or `nil` if not applicable.
    ///   - entityID: The entity ID to check, or `nil` if not applicable.
    ///   - database: The database connection to use for the query.
    /// - Returns: `true` if an active notation exists, `false` otherwise.
    /// - Throws: Database errors that occur during the query.
    public static func hasActiveAssignment(
        templateID: Int32,
        personID: Int32?,
        entityID: Int32?,
        on database: Database
    ) async throws -> Bool {
        var query = Notation.query(on: database)
            .filter(\.$template.$id == templateID)
            .filter(\.$state == .open)

        if let personID = personID {
            query = query.filter(\.$person.$id == personID)
        } else {
            query = query.filter(\.$person.$id == nil)
        }

        if let entityID = entityID {
            query = query.filter(\.$entity.$id == entityID)
        } else {
            query = query.filter(\.$entity.$id == nil)
        }

        let count = try await query.count()
        return count > 0
    }
}

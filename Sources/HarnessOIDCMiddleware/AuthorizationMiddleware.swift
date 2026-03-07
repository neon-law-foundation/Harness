import FluentKit
import HarnessDAL
import Hummingbird

/// Hummingbird middleware that resolves a verified OIDC subject to a database `User` and
/// populates `context.userRole` with the user's role.
///
/// Must run after ``OIDCAuthMiddleware`` so that `context.authenticatedUser` is already set.
public struct AuthorizationMiddleware<Context: AuthorizedRequestContext>: RouterMiddleware {
    public let db: any Database

    public init(db: any Database) {
        self.db = db
    }

    public func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        guard let authenticatedUser = context.authenticatedUser else {
            throw HTTPError(.unauthorized)
        }
        guard
            let user = try await User.query(on: db)
                .filter(\.$sub == authenticatedUser.sub)
                .first()
        else {
            throw HTTPError(.unauthorized)
        }
        var ctx = context
        ctx.userRole = user.role
        return try await next(request, ctx)
    }
}

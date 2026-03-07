import HarnessDAL
import Hummingbird

/// A request context that carries an authenticated OIDC user.
public protocol AuthenticatedRequestContext: RequestContext {
    var authenticatedUser: AuthenticatedUser? { get set }
}

/// A request context that additionally carries the resolved database role.
public protocol AuthorizedRequestContext: AuthenticatedRequestContext {
    var userRole: UserRole? { get set }
}

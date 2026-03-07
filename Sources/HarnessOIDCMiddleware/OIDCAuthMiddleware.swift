import AsyncHTTPClient
import Foundation
import Hummingbird
import JWTKit
import NIOFoundationCompat

/// Hummingbird middleware that verifies a standard OIDC ID token on every request.
///
/// Expects an `Authorization: Bearer <id-token>` header. On success, populates
/// `context.authenticatedUser` with the subject and email from the token.
public struct OIDCAuthMiddleware<Context: AuthenticatedRequestContext>: RouterMiddleware {
    public let keyCollection: JWTKeyCollection
    public let issuerURL: String
    public let clientID: String

    public init(keyCollection: JWTKeyCollection, issuerURL: String, clientID: String) {
        self.keyCollection = keyCollection
        self.issuerURL = issuerURL
        self.clientID = clientID
    }

    public func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        guard
            let authHeader = request.headers[.authorization],
            authHeader.hasPrefix("Bearer ")
        else {
            throw HTTPError(.unauthorized)
        }
        let token = String(authHeader.dropFirst("Bearer ".count))
        let payload: OIDCIDTokenPayload
        do {
            payload = try await keyCollection.verify(token, as: OIDCIDTokenPayload.self)
        } catch {
            throw HTTPError(.unauthorized)
        }
        guard payload.iss.value == issuerURL else {
            throw HTTPError(.unauthorized)
        }
        guard payload.aud.value.contains(clientID) else {
            throw HTTPError(.unauthorized)
        }
        var ctx = context
        ctx.authenticatedUser = AuthenticatedUser(
            sub: payload.sub.value,
            email: payload.email
        )
        return try await next(request, ctx)
    }
}

/// Minimal OIDC discovery document — only the fields this library needs.
private struct OIDCDiscoveryDocument: Decodable {
    let jwksURI: String

    enum CodingKeys: String, CodingKey {
        case jwksURI = "jwks_uri"
    }
}

/// Errors that can occur while building the JWT key collection from an OIDC provider.
public enum OIDCConfigError: Error {
    case invalidIssuerURL
    case invalidJWKSURL
}

/// Builds a `JWTKeyCollection` for OIDC token verification.
///
/// - In **production** (`env == "production"`), fetches the JWKS from the OIDC discovery
///   document at `{issuerURL}/.well-known/openid-configuration`, which works with Cognito,
///   Auth0, Dex, or any standards-compliant OIDC provider.
/// - In **non-production** environments, uses `injectedCollection` directly to avoid
///   network calls during local development and testing.
///
/// - Parameters:
///   - env: The current environment string. Only `"production"` triggers the network fetch.
///   - issuerURL: The OIDC issuer URL (e.g. a Cognito User Pool URL).
///   - clientID: The OIDC client/app ID.
///   - injectedCollection: A pre-built key collection to use in non-production environments.
///     Pass `nil` only when `env == "production"`.
public func buildJWTKeyCollection(
    env: String,
    issuerURL: String,
    clientID: String,
    injectedCollection: JWTKeyCollection?
) async throws -> JWTKeyCollection {
    guard env == "production" else {
        return injectedCollection ?? JWTKeyCollection()
    }

    let httpClient = HTTPClient.shared
    let discoveryURLString = "\(issuerURL)/.well-known/openid-configuration"
    guard URL(string: discoveryURLString) != nil else {
        throw OIDCConfigError.invalidIssuerURL
    }
    let discoveryResponse = try await httpClient.get(url: discoveryURLString).get()
    guard var discoveryBody = discoveryResponse.body else {
        throw OIDCConfigError.invalidIssuerURL
    }
    let discoveryData = discoveryBody.readData(length: discoveryBody.readableBytes) ?? Data()
    let discovery = try JSONDecoder().decode(OIDCDiscoveryDocument.self, from: discoveryData)

    guard URL(string: discovery.jwksURI) != nil else {
        throw OIDCConfigError.invalidJWKSURL
    }
    let jwksResponse = try await httpClient.get(url: discovery.jwksURI).get()
    guard var jwksBody = jwksResponse.body else {
        throw OIDCConfigError.invalidJWKSURL
    }
    let jwksData = jwksBody.readData(length: jwksBody.readableBytes) ?? Data()
    let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)

    let keyCollection = JWTKeyCollection()
    try await keyCollection.add(jwks: jwks)
    return keyCollection
}

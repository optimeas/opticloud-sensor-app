import Foundation

/// The claims the app reads from the user's access token, a JWT (see `docs/spec/sign-in.md`, The session).
public struct AccessTokenClaims: Hashable, Sendable, Decodable {
    public let tenantId: String?
    public let projectId: String?
    public let userId: String?
    public let authorityDataId: String?
    /// The moment the token expires, in seconds since 1970.
    public let exp: Int64?

    /// Reads the claims of a JWT without checking its signature; the server checks it.
    public init(jwt: String) throws {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2, let data = Data(base64URLEncoded: String(parts[1])) else {
            throw OptiCloudError.unexpectedAnswer
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }

    public var expiresAt: Date? {
        exp.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }

    /// The identifiers a note needs, if the token has all of them.
    public var noteClaims: NoteClaims? {
        guard let tenantId, let projectId, let authorityDataId else { return nil }
        return NoteClaims(tenantId: tenantId, projectId: projectId, authorityDataId: authorityDataId)
    }
}

extension Data {
    init?(base64URLEncoded text: String) {
        var base64 = text.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        self.init(base64Encoded: base64)
    }
}

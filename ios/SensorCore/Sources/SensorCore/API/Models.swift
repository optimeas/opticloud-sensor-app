import Foundation

/// An identifier as optiCLOUD writes it: either a plain string or an object with `id` and `entityType`.
public struct EntityId: Hashable, Sendable, Codable {
    public let id: String

    public init(_ id: String) {
        self.id = id
    }

    private enum CodingKeys: String, CodingKey { case id }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let id = try? single.decode(String.self) {
            self.id = id
        } else {
            id = try decoder.container(keyedBy: CodingKeys.self).decode(String.self, forKey: .id)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}

/// A role of the user. Each role belongs to one tenant (see `docs/spec/sign-in.md`, Tenants).
public struct Role: Hashable, Sendable, Decodable, Identifiable {
    public struct Tenant: Hashable, Sendable, Decodable {
        public let id: EntityId
        public let name: String
    }

    public let authorityId: EntityId
    public let authority: String?
    public let tenant: Tenant
    public let enabled: Bool
    public let projectCount: Int?

    public var id: String { authorityId.id }
}

/// The access token and the refresh token of the user's session.
public struct TokenPair: Hashable, Sendable, Codable {
    public let token: String
    public let refreshToken: String

    public init(token: String, refreshToken: String) {
        self.token = token
        self.refreshToken = refreshToken
    }
}

/// The answer to signing in with a role.
public enum LoginResult: Hashable, Sendable {
    case signedIn(TokenPair)
    /// The server has sent a code to `email`; confirm it with the two-factor token.
    case codeRequired(twoFactorToken: String, email: String)
}

struct LoginResponse: Decodable {
    let token: String?
    let refreshToken: String?
    let twoFactorRequired: Bool?
    let twoFactorToken: String?
    let twoFactorEmail: String?

    func result() throws -> LoginResult {
        if twoFactorRequired == true {
            guard let twoFactorToken else { throw OptiCloudError.unexpectedAnswer }
            return .codeRequired(twoFactorToken: twoFactorToken, email: twoFactorEmail ?? "")
        }
        return .signedIn(try tokens())
    }

    func tokens() throws -> TokenPair {
        guard let token, let refreshToken else { throw OptiCloudError.unexpectedAnswer }
        return TokenPair(token: token, refreshToken: refreshToken)
    }
}

/// A project in the project tree of a tenant.
public struct Project: Hashable, Sendable, Decodable, Identifiable {
    public let projectId: EntityId
    public let name: String
    public let children: [Project]?

    public var id: String { projectId.id }

    private enum CodingKeys: String, CodingKey {
        case projectId = "id", name, children
    }

    public init(id: String, name: String, children: [Project]? = nil) {
        projectId = EntityId(id)
        self.name = name
        self.children = children
    }

    /// The children, or nil for a leaf, as `List(children:)` expects.
    public var childProjects: [Project]? {
        guard let children, !children.isEmpty else { return nil }
        return children
    }

    /// This project and all projects below it, depth first.
    public var flattened: [Project] {
        [self] + (children ?? []).flatMap(\.flattened)
    }
}

/// A device in optiCLOUD.
public struct Device: Hashable, Sendable, Decodable, Identifiable {
    public let deviceId: EntityId
    public let name: String
    public let type: String?
    public let label: String?

    public var id: String { deviceId.id }

    private enum CodingKeys: String, CodingKey {
        case deviceId = "id", name, type, label
    }

    /// Whether the device is one of the app (see `docs/spec/sign-in.md`, Marking devices of the app).
    public var isSensorAppDevice: Bool { type == SensorCore.deviceType }
}

struct Page<Element: Decodable>: Decodable {
    let data: [Element]
    let hasNext: Bool
}

/// The credentials of a device (see `docs/spec/sign-in.md`, Reading the access token).
public struct DeviceCredentials: Hashable, Sendable, Decodable {
    public let credentialsType: String
    public let credentialsId: String?
    public let enabled: Bool?

    public static let accessTokenType = "ACCESS_TOKEN"
}

/// One attribute as the REST interface lists it.
public struct AttributeEntry: Hashable, Sendable, Decodable {
    public let key: String
    public let value: JSONValue
    public let lastUpdateTs: Int64?
}

/// The error body of the REST interface (see `docs/spec/sign-in.md`, Errors).
public struct APIErrorBody: Hashable, Sendable, Decodable {
    public let status: Int?
    public let message: String?
    public let errorCode: Int?
}

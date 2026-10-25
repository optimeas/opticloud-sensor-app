import Foundation

/// Errors of the REST interface.
public enum OptiCloudError: Error, Hashable, Sendable {
    /// The server answered with an error body.
    case api(status: Int, body: APIErrorBody)
    /// The server answered with an error and no readable body.
    case http(status: Int)
    /// The server did not accept e-mail address and password, but sent no `errorCode`.
    case signInRejected(status: Int, message: String?)
    /// The answer did not have the expected form.
    case unexpectedAnswer
    /// The request needs a signed-in user.
    case notSignedIn

    /// The `errorCode` of the server, if there is one.
    public var errorCode: Int? {
        switch self {
        case .api(_, let body): body.errorCode
        case .signInRejected: Code.signInFailed
        default: nil
        }
    }

    /// The error codes the app distinguishes (see `docs/spec/sign-in.md`, Errors).
    public enum Code {
        public static let signInFailed = 10
        public static let tokenExpired = 11
        public static let accountExpired = 12
        public static let licenseLimit = 14
        public static let permissionMissing = 20
        public static let invalidRequest = 31
        public static let tooManyAttempts = 33
    }
}

/// Sends HTTP requests. `URLSession` is the transport of the app; tests replace it.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

extension URLSession: HTTPTransport {
    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        guard let http = response as? HTTPURLResponse else { throw OptiCloudError.unexpectedAnswer }
        return (data, http)
    }
}

/// The REST interface of optiCLOUD for sign-in, projects, devices, and their binding
/// (see `docs/spec/sign-in.md`).
///
/// The client keeps the user's tokens. It renews the session shortly before the access token expires and,
/// when the server reports an expired token, renews it and repeats the request once.
public actor OptiCloudClient {
    public let address: ServerAddress
    private let transport: HTTPTransport
    private let now: @Sendable () -> Date
    private var tokens: TokenPair?
    private var refreshTask: Task<TokenPair, Error>?
    private var tokensChanged: (@Sendable (TokenPair?) -> Void)?

    /// Renew the session when the access token expires within this time.
    public static let renewalMargin: TimeInterval = 120

    public init(
        address: ServerAddress,
        tokens: TokenPair? = nil,
        transport: HTTPTransport = URLSession.shared,
        now: @escaping @Sendable () -> Date = Date.init,
        tokensChanged: (@Sendable (TokenPair?) -> Void)? = nil
    ) {
        self.address = address
        self.tokens = tokens
        self.transport = transport
        self.now = now
        self.tokensChanged = tokensChanged
    }

    /// Called whenever the tokens change, so that the app can store the refresh token. Nil means signed out.
    public func onTokensChanged(_ handler: @escaping @Sendable (TokenPair?) -> Void) {
        tokensChanged = handler
    }

    public var isSignedIn: Bool { tokens != nil }

    /// The claims of the current access token.
    public var claims: AccessTokenClaims? {
        tokens.flatMap { try? AccessTokenClaims(jwt: $0.token) }
    }

    /// Forgets the tokens. The server does not invalidate them.
    public func signOut() {
        refreshTask?.cancel()
        refreshTask = nil
        setTokens(nil)
    }

    // MARK: Sign-in

    /// The user's roles, one per tenant. Issues no token.
    ///
    /// An unknown e-mail address is answered with status 400 and no `errorCode`; this counts as sign-in failed.
    public func roles(username: String, password: String) async throws -> [Role] {
        do {
            return try await send("POST", "/api/noauth/authorization", body: ["username": username, "password": password])
        } catch OptiCloudError.api(400, let body) where body.errorCode == nil {
            throw OptiCloudError.signInRejected(status: 400, message: body.message)
        }
    }

    /// Signs in with a role. If the server requires a code, confirm it with `verify(twoFactorToken:code:)`.
    public func login(username: String, password: String, authorityId: String) async throws -> LoginResult {
        let response: LoginResponse = try await send(
            "POST", "/api/auth/login",
            body: ["username": username, "password": password, "authorityId": authorityId]
        )
        let result = try response.result()
        if case .signedIn(let pair) = result { setTokens(pair) }
        return result
    }

    /// Confirms the code sent by e-mail.
    public func verify(twoFactorToken: String, code: String) async throws {
        let response: LoginResponse = try await send(
            "POST", "/api/noauth/2fa/verify", body: ["twoFactorToken": twoFactorToken, "code": code]
        )
        setTokens(try response.tokens())
    }

    /// Renews the session. Concurrent calls share one request.
    @discardableResult
    public func refresh() async throws -> TokenPair {
        if let refreshTask { return try await refreshTask.value }
        guard let refreshToken = tokens?.refreshToken else { throw OptiCloudError.notSignedIn }
        let task = Task { () throws -> TokenPair in
            let response: LoginResponse = try await self.send(
                "POST", "/api/auth/token", body: ["refreshToken": refreshToken]
            )
            return try response.tokens()
        }
        refreshTask = task
        defer { refreshTask = nil }
        let pair = try await task.value
        setTokens(pair)
        return pair
    }

    // MARK: Projects

    /// The project tree of the role.
    public func projects() async throws -> [Project] {
        try await authorized("GET", "/api/projects/enabled")
    }

    /// Moves the session into another project. The answer is a new token pair.
    public func selectProject(id: String) async throws {
        let response: LoginResponse = try await authorized("POST", "/api/auth/selectProject/\(id)")
        setTokens(try response.tokens())
    }

    // MARK: Devices

    /// All devices of the project of the session, of every type. Filter with `Device.isSensorAppDevice`.
    public func devices(tenantId: String, projectId: String, textSearch: String? = nil) async throws -> [Device] {
        var devices: [Device] = []
        var page = 0
        while true {
            var query = [
                URLQueryItem(name: "projectId", value: projectId),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "page", value: String(page)),
            ]
            if let textSearch, !textSearch.isEmpty {
                query.append(URLQueryItem(name: "textSearch", value: textSearch))
            }
            let result: Page<Device> = try await authorized("GET", "/api/tenants/\(tenantId)/devices", query: query)
            devices += result.data
            guard result.hasNext else { return devices }
            page += 1
        }
    }

    /// Creates a device of the app in the project of the session.
    public func createDevice(name: String) async throws -> Device {
        try await authorized("POST", "/api/devices", body: ["name": name, "type": SensorCore.deviceType])
    }

    public func credentials(deviceId: String) async throws -> DeviceCredentials {
        try await authorized("GET", "/api/device/\(deviceId)/credentials")
    }

    // MARK: Attributes

    public func sharedAttributes(deviceId: String) async throws -> [AttributeEntry] {
        try await authorized("GET", "/api/plugins/telemetry/DEVICE/\(deviceId)/values/attributes/SHARED_SCOPE")
    }

    public func setSharedAttributes(deviceId: String, _ attributes: [String: JSONValue]) async throws {
        let _: Empty = try await authorized(
            "POST", "/api/plugins/telemetry/DEVICE/\(deviceId)/attributes/SHARED_SCOPE", body: attributes
        )
    }

    // MARK: Requests

    private struct Empty: Decodable {}

    private func setTokens(_ pair: TokenPair?) {
        tokens = pair
        tokensChanged?(pair)
    }

    /// Sends a request with the user's access token.
    private func authorized<Answer: Decodable>(
        _ method: String, _ path: String, query: [URLQueryItem] = [], body: (some Encodable & Sendable)? = nil as String?
    ) async throws -> Answer {
        guard tokens != nil else { throw OptiCloudError.notSignedIn }
        if let expiresAt = claims?.expiresAt, expiresAt.timeIntervalSince(now()) < Self.renewalMargin {
            try await refresh()
        }
        do {
            return try await send(method, path, query: query, body: body, token: tokens?.token)
        } catch let error as OptiCloudError where error.errorCode == OptiCloudError.Code.tokenExpired {
            try await refresh()
            return try await send(method, path, query: query, body: body, token: tokens?.token)
        }
    }

    private func send<Answer: Decodable>(
        _ method: String, _ path: String, query: [URLQueryItem] = [],
        body: (some Encodable & Sendable)? = nil as String?, token: String? = nil
    ) async throws -> Answer {
        var request = URLRequest(url: address.url(path: path, query: query))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "X-Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await transport.send(request)
        guard (200..<300).contains(response.statusCode) else {
            if let body = try? JSONDecoder().decode(APIErrorBody.self, from: data) {
                throw OptiCloudError.api(status: response.statusCode, body: body)
            }
            throw OptiCloudError.http(status: response.statusCode)
        }
        if Answer.self == Empty.self, data.isEmpty || (try? JSONDecoder().decode(JSONValue.self, from: data)) != nil {
            return Empty() as! Answer
        }
        do {
            return try JSONDecoder().decode(Answer.self, from: data)
        } catch {
            throw OptiCloudError.unexpectedAnswer
        }
    }
}

import Foundation
import SensorCore
import Synchronization
import Testing

/// A transport that answers from a list of prepared answers and records the requests.
final class MockTransport: HTTPTransport {
    struct Answer {
        let status: Int
        let body: String
    }

    private let state: Mutex<(answers: [Answer], requests: [URLRequest])>

    init(_ answers: [Answer]) {
        state = Mutex((answers, []))
    }

    var requests: [URLRequest] { state.withLock { $0.requests } }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let answer = state.withLock { state in
            state.requests.append(request)
            return state.answers.removeFirst()
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: answer.status, httpVersion: nil, headerFields: nil)!
        return (Data(answer.body.utf8), response)
    }
}

/// A JWT with the given claims and no valid signature; the client does not check it.
func jwt(_ claims: [String: Any]) -> String {
    let header = Data(#"{"alg":"none"}"#.utf8).base64URL
    let payload = try! JSONSerialization.data(withJSONObject: claims).base64URL
    return "\(header).\(payload).signature"
}

extension Data {
    var base64URL: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

func body(of request: URLRequest) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: request.httpBody ?? Data())
}

struct OptiCloudClientTests {
    let address = ServerAddress(parsing: "https://cloud.example.com")!
    let now = Date(timeIntervalSince1970: 1_760_000_000)

    let validToken = jwt(["tenantId": "t1", "projectId": "p1", "userId": "u1", "authorityDataId": "a1", "exp": 1_760_003_600])

    @Test func addressNeedsHTTPS() {
        #expect(ServerAddress(parsing: "http://cloud.example.com") == nil)
        #expect(ServerAddress(parsing: "cloud.example.com") == nil)
        #expect(ServerAddress(parsing: "https://") == nil)
        #expect(ServerAddress(parsing: " https://cloud.example.com/home/ ")?.text == "https://cloud.example.com")
        #expect(ServerAddress.official.host == "dashboard.opticloud.io")
    }

    @Test func rolesAreReadWithIdentifiersInBothForms() async throws {
        let transport = MockTransport([.init(status: 200, body: """
            [{"authorityId":{"id":"r1"},"authority":"TENANT_ADMIN","tenant":{"id":"t1","name":"Example"},"enabled":true,"projectCount":2},
             {"authorityId":{"entityType":"AUTHORITY_DATA","id":"r2"},"tenant":{"id":{"entityType":"TENANT","id":"t2"},"name":"Other"},"enabled":false}]
            """)])
        let client = OptiCloudClient(address: address, transport: transport, now: { now })
        let roles = try await client.roles(username: "user@example.com", password: "secret")
        #expect(roles.map(\.id) == ["r1", "r2"])
        #expect(roles.map(\.tenant.id.id) == ["t1", "t2"])
        #expect(roles.map(\.enabled) == [true, false])
        let request = try #require(transport.requests.first)
        #expect(request.url?.absoluteString == "https://cloud.example.com/api/noauth/authorization")
        #expect(request.value(forHTTPHeaderField: "X-Authorization") == nil)
        #expect(try body(of: request) == .object(["username": .string("user@example.com"), "password": .string("secret")]))
    }

    @Test func loginWithCodeRequired() async throws {
        let transport = MockTransport([
            .init(status: 200, body: #"{"twoFactorRequired":true,"twoFactorToken":"tf","twoFactorEmail":"u***@example.com"}"#),
            .init(status: 200, body: #"{"token":"\#(validToken)","refreshToken":"r","twoFactorRequired":false}"#),
        ])
        let client = OptiCloudClient(address: address, transport: transport, now: { now })
        let result = try await client.login(username: "u", password: "p", authorityId: "r1")
        #expect(result == .codeRequired(twoFactorToken: "tf", email: "u***@example.com"))
        #expect(await !client.isSignedIn)
        try await client.verify(twoFactorToken: "tf", code: "123456")
        #expect(await client.isSignedIn)
        #expect(await client.claims?.noteClaims == NoteClaims(tenantId: "t1", projectId: "p1", authorityDataId: "a1"))
        #expect(transport.requests.last?.url?.path() == "/api/noauth/2fa/verify")
    }

    @Test func authorizedRequestsSendTheToken() async throws {
        let transport = MockTransport([.init(status: 200, body: #"{"data":[],"hasNext":false}"#)])
        let client = OptiCloudClient(
            address: address, tokens: TokenPair(token: validToken, refreshToken: "r"), transport: transport, now: { now }
        )
        _ = try await client.devices(tenantId: "t1", projectId: "p1")
        let request = try #require(transport.requests.first)
        #expect(request.value(forHTTPHeaderField: "X-Authorization") == "Bearer \(validToken)")
        #expect(request.url?.absoluteString == "https://cloud.example.com/api/tenants/t1/devices?projectId=p1&limit=100&page=0")
    }

    @Test func devicesAreReadPageByPage() async throws {
        let transport = MockTransport([
            .init(status: 200, body: #"{"data":[{"id":{"entityType":"DEVICE","id":"d1"},"name":"A","type":"optiCLOUD Sensor App"}],"hasNext":true}"#),
            .init(status: 200, body: #"{"data":[{"id":{"entityType":"DEVICE","id":"d2"},"name":"B","type":"Machine"}],"hasNext":false}"#),
        ])
        let client = OptiCloudClient(
            address: address, tokens: TokenPair(token: validToken, refreshToken: "r"), transport: transport, now: { now }
        )
        let devices = try await client.devices(tenantId: "t1", projectId: "p1")
        #expect(devices.map(\.id) == ["d1", "d2"])
        #expect(devices.map(\.isSensorAppDevice) == [true, false])
        #expect(transport.requests.last?.url?.query()?.contains("page=1") == true)
    }

    @Test func expiredTokenIsRenewedAndTheRequestRepeatedOnce() async throws {
        let renewed = jwt(["exp": 1_760_007_200])
        let transport = MockTransport([
            .init(status: 401, body: #"{"status":401,"message":"Token has expired","errorCode":11}"#),
            .init(status: 200, body: #"{"token":"\#(renewed)","refreshToken":"r2"}"#),
            .init(status: 200, body: #"[]"#),
        ])
        let client = OptiCloudClient(
            address: address, tokens: TokenPair(token: validToken, refreshToken: "r1"), transport: transport, now: { now }
        )
        let stored = Mutex<TokenPair?>(nil)
        await client.onTokensChanged { pair in stored.withLock { $0 = pair } }
        _ = try await client.projects()
        #expect(transport.requests.map { $0.url!.path() } == ["/api/projects/enabled", "/api/auth/token", "/api/projects/enabled"])
        #expect(try body(of: transport.requests[1]) == .object(["refreshToken": .string("r1")]))
        #expect(transport.requests[2].value(forHTTPHeaderField: "X-Authorization") == "Bearer \(renewed)")
        #expect(stored.withLock { $0 } == TokenPair(token: renewed, refreshToken: "r2"))
    }

    @Test func tokenCloseToExpiryIsRenewedBeforeTheRequest() async throws {
        let expiring = jwt(["exp": 1_760_000_060])
        let transport = MockTransport([
            .init(status: 200, body: #"{"token":"\#(validToken)","refreshToken":"r2"}"#),
            .init(status: 200, body: #"[]"#),
        ])
        let client = OptiCloudClient(
            address: address, tokens: TokenPair(token: expiring, refreshToken: "r1"), transport: transport, now: { now }
        )
        _ = try await client.projects()
        #expect(transport.requests.map { $0.url!.path() } == ["/api/auth/token", "/api/projects/enabled"])
    }

    @Test func errorBodyIsReported() async throws {
        let transport = MockTransport([
            .init(status: 400, body: #"{"status":400,"message":"Device with such name already exists!","errorCode":31}"#),
        ])
        let client = OptiCloudClient(
            address: address, tokens: TokenPair(token: validToken, refreshToken: "r"), transport: transport, now: { now }
        )
        await #expect(throws: OptiCloudError.self) {
            _ = try await client.createDevice(name: "Phone")
        }
        #expect(try body(of: transport.requests[0]) == .object(["name": .string("Phone"), "type": .string("optiCLOUD Sensor App")]))
        do {
            _ = try await OptiCloudClient(
                address: address, tokens: TokenPair(token: validToken, refreshToken: "r"),
                transport: MockTransport([.init(status: 401, body: #"{"errorCode":10}"#)]), now: { now }
            ).projects()
        } catch let error as OptiCloudError {
            #expect(error.errorCode == OptiCloudError.Code.signInFailed)
        }
    }

    @Test func requestsWithoutSessionFail() async {
        let client = OptiCloudClient(address: address, transport: MockTransport([]), now: { now })
        await #expect(throws: OptiCloudError.notSignedIn) {
            _ = try await client.projects()
        }
    }

    @Test func projectTreeAndCredentials() async throws {
        let transport = MockTransport([
            .init(status: 200, body: #"[{"id":{"id":"root"},"name":"Root","children":[{"id":{"id":"p1"},"name":"Main","children":[]}]}]"#),
            .init(status: 200, body: #"{"credentialsType":"ACCESS_TOKEN","credentialsId":"device-token","enabled":true}"#),
            .init(status: 200, body: #"[{"key":"sensorAppInstallation","value":"abc","lastUpdateTs":1760000000000}]"#),
            .init(status: 200, body: ""),
        ])
        let client = OptiCloudClient(
            address: address, tokens: TokenPair(token: validToken, refreshToken: "r"), transport: transport, now: { now }
        )
        let projects = try await client.projects()
        #expect(projects.flatMap(\.flattened).map(\.name) == ["Root", "Main"])
        #expect(projects[0].childProjects?.first?.childProjects == nil)
        let credentials = try await client.credentials(deviceId: "d1")
        #expect(credentials.credentialsId == "device-token")
        let attributes = try await client.sharedAttributes(deviceId: "d1")
        #expect(attributes.first?.value == .string("abc"))
        try await client.setSharedAttributes(deviceId: "d1", ["sensorAppInstallation": .string("abc")])
        #expect(transport.requests.last?.url?.path() == "/api/plugins/telemetry/DEVICE/d1/attributes/SHARED_SCOPE")
    }
}

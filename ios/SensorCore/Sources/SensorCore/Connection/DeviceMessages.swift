import Foundation

/// Topics and payloads of the MQTT messages other than telemetry (see `docs/spec/messages.md`).
public enum DeviceMessages {
    public static let attributesTopic = "v2/json/devices/me/attributes"
    public static let attributeRequestPrefix = "v2/json/devices/me/attributes/request/"
    public static let attributeResponsePrefix = "v2/json/devices/me/attributes/response/"
    public static let rpcRequestPrefix = "v2/json/devices/me/rpc/request/"
    public static let rpcResponsePrefix = "v2/json/devices/me/rpc/response/"

    /// The topic filters the app subscribes to after every connect (see `docs/spec/connection.md`, Subscriptions).
    public static let subscriptions = [
        attributesTopic,
        attributeResponsePrefix + "+",
        rpcRequestPrefix + "+",
    ]

    /// The shared attribute that binds the device to one phone.
    public static let bindingKey = "sensorAppInstallation"
    /// The shared attributes the app requests after every connect.
    public static let requestedSharedKeys = ["sendRate", "sensors", "dashboard", bindingKey]

    // MARK: Attributes

    /// The payload of a request for shared attributes. The keys are one string, separated by commas.
    public static func attributeRequest(sharedKeys: [String]) throws -> Data {
        try encoder.encode(["sharedKeys": sharedKeys.joined(separator: ",")])
    }

    /// The payload of client attributes: one flat object.
    public static func clientAttributes(_ values: [String: TelemetryValue]) throws -> Data {
        try encoder.encode(values.filter { $0.value.isSendable })
    }

    /// The shared attributes of an answer to an attribute request or of a change; both have the member `shared`.
    /// A missing scope gives an empty result. In a change, a key with the value `null` was deleted.
    public static func sharedAttributes(from payload: Data) throws -> [String: JSONValue] {
        try decoder.decode(AttributeResponse.self, from: payload).shared ?? [:]
    }

    // MARK: Commands

    /// A command from the server.
    public struct Command: Hashable, Sendable {
        public var id: Int
        public var method: String
        public var params: JSONValue?

        public init(id: Int, method: String, params: JSONValue? = nil) {
            self.id = id
            self.method = method
            self.params = params
        }
    }

    /// Reads a command. Returns nil if the topic or the payload does not have the form of a command.
    public static func command(topic: String, payload: Data) -> Command? {
        guard let id = requestId(topic: topic, prefix: rpcRequestPrefix),
              let body = try? decoder.decode(CommandBody.self, from: payload)
        else { return nil }
        return Command(id: id, method: body.method, params: body.params)
    }

    public static func commandResponseTopic(id: Int) -> String {
        rpcResponsePrefix + String(id)
    }

    /// The payload of an answer to a command: a JSON object.
    public static func commandResponse(_ answer: [String: JSONValue]) throws -> Data {
        try encoder.encode(answer)
    }

    // MARK: Topics

    /// The identifier at the end of a request or response topic: a positive whole number.
    public static func requestId(topic: String, prefix: String) -> Int? {
        guard topic.hasPrefix(prefix), let id = Int(topic.dropFirst(prefix.count)), id > 0 else { return nil }
        return id
    }

    private struct AttributeResponse: Decodable {
        var shared: [String: JSONValue]?
    }

    private struct CommandBody: Decodable {
        var method: String
        var params: JSONValue?
    }

    private static let decoder = JSONDecoder()
    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}

/// What the app does with the answer to the binding check (see `docs/spec/connection.md`, Checking the binding).
public enum BindingCheck: Hashable, Sendable {
    case same
    case other
    case missing

    public init(sharedAttributes: [String: JSONValue], installationId: String) {
        switch sharedAttributes[DeviceMessages.bindingKey] {
        case nil, .null?: self = .missing
        case .string(installationId)?: self = .same
        default: self = .other
        }
    }
}

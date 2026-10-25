/// A value of a telemetry sample or a client attribute: a number, a boolean, or a string
/// (see `docs/spec/messages.md`, Telemetry).
public enum TelemetryValue: Hashable, Sendable {
    case number(Double)
    case bool(Bool)
    case string(String)

    /// Whether the value may be sent. A number that is not finite cannot be sent.
    public var isSendable: Bool {
        if case .number(let value) = self { return value.isFinite }
        return true
    }
}

extension TelemetryValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        // Adding 0 turns a negative zero into 0, which is sent as `0`.
        case .number(let value): try container.encode(value + 0)
        case .bool(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        }
    }
}

extension TelemetryValue: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral,
    ExpressibleByBooleanLiteral, ExpressibleByStringLiteral
{
    public init(floatLiteral value: Double) { self = .number(value) }
    public init(integerLiteral value: Int) { self = .number(Double(value)) }
    public init(booleanLiteral value: Bool) { self = .bool(value) }
    public init(stringLiteral value: String) { self = .string(value) }
}

/// Values measured at one moment. `ts` is the moment of measurement in milliseconds since 1970.
public struct Sample: Hashable, Codable, Sendable {
    public var ts: Int64
    public var values: [String: TelemetryValue]

    public init(ts: Int64, values: [String: TelemetryValue]) {
        self.ts = ts
        self.values = values
    }
}

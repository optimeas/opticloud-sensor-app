import Foundation

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
        // A Decimal is written as its digits, so the number keeps the plain notation.
        case .number(let value): try container.encode(Decimal(string: Self.plainNotation(value))!)
        case .bool(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        }
    }

    /// A finite number in plain notation (see `docs/spec/sensors.md`, Sending on change): without an exponent,
    /// a whole number without a decimal point, a negative zero as `0`. It has the shortest digits that
    /// read back as the same number.
    static func plainNotation(_ value: Double) -> String {
        // Adding 0 turns a negative zero into 0. The description has the shortest digits, maybe with an exponent.
        let text = (value + 0).description
        let negative = text.hasPrefix("-")
        let unsigned = negative ? text.dropFirst() : Substring(text)
        let parts = unsigned.split(separator: "e", maxSplits: 1)
        let exponent = parts.count == 2 ? Int(parts[1])! : 0
        let mantissa = parts[0].split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let fraction = mantissa.count == 2 ? mantissa[1] : ""
        var digits = Array(mantissa[0] + fraction)
        // The decimal point stands after this many digits.
        var point = mantissa[0].count + exponent
        if point <= 0 {
            digits.insert(contentsOf: repeatElement("0", count: 1 - point), at: 0)
            point = 1
        }
        if point > digits.count {
            digits.append(contentsOf: repeatElement("0", count: point - digits.count))
        }
        var whole = String(digits[..<point])
        var decimals = String(digits[point...])
        while whole.count > 1 && whole.hasPrefix("0") { whole.removeFirst() }
        while decimals.hasSuffix("0") { decimals.removeLast() }
        let result = decimals.isEmpty ? whole : whole + "." + decimals
        return negative && result != "0" ? "-" + result : result
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

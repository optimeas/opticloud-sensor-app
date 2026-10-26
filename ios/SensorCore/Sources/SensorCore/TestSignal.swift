import Foundation

/// The values of the group `test`, known in advance so that the delivery can be checked on the server
/// (see `docs/spec/sensors.md`, `test`).
public enum TestSignal {
    /// The period of `testSine` in milliseconds.
    public static let period: Int64 = 60_000

    /// `testSine` for the time stamp of a sample, not yet rounded.
    public static func sine(at ts: Int64) -> Double {
        let phase = ((ts % period) + period) % period
        return sin(2 * .pi * Double(phase) / Double(period))
    }

    /// The values of a sample. `counter` is the number of the tick; nil for a sample that is not a tick.
    public static func values(at ts: Int64, counter: Int?) -> [String: TelemetryValue] {
        var values: [String: TelemetryValue] = ["testSine": .number(sine(at: ts))]
        if let counter { values["testCounter"] = .number(Double(counter)) }
        return values
    }
}

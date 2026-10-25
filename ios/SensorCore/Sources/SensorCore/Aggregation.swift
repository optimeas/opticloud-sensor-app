/// Mean, minimum, and maximum of the measurements of one value between two ticks
/// (see `docs/spec/sensors.md`, Sampling).
public struct Aggregate: Hashable, Sendable {
    public private(set) var count = 0
    public private(set) var minimum = Double.infinity
    public private(set) var maximum = -Double.infinity
    private var sum = 0.0

    public init() {}

    public init(_ measurements: some Sequence<Double>) {
        for value in measurements { add(value) }
    }

    public mutating func add(_ value: Double) {
        guard value.isFinite else { return }
        count += 1
        sum += value
        minimum = min(minimum, value)
        maximum = max(maximum, value)
    }

    /// Nil if there was no measurement.
    public var mean: Double? {
        count > 0 ? sum / Double(count) : nil
    }

    /// The values to send for `key`: the mean under `key`, minimum and maximum under `key` with `Min` and `Max`,
    /// rounded to `resolution`. Empty if there was no measurement, so the keys are left out.
    public func values(key: String, resolution: Resolution?) -> [String: TelemetryValue] {
        guard let mean else { return [:] }
        let round = { (value: Double) in resolution?.round(value) ?? value }
        return [
            key: .number(round(mean)),
            key + "Min": .number(round(minimum)),
            key + "Max": .number(round(maximum)),
        ]
    }

    /// The magnitude of a vector with three axes.
    public static func magnitude(x: Double, y: Double, z: Double) -> Double {
        (x * x + y * y + z * z).squareRoot()
    }
}

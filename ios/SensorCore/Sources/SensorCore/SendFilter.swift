/// The send mode (see `docs/spec/configuration.md`).
public enum SendMode: String, Codable, Sendable, CaseIterable {
    /// Only values that changed since they were last sent, and a full sample every 60 seconds.
    case onChange
    /// All selected values at every tick.
    case everyTick
}

/// Chooses the values sent at each tick and rounds them (see `docs/spec/sensors.md`, Sending on change).
///
/// "Sent" means handed to the offline queue. Create a new filter when transmission is switched on.
public struct SendFilter: Sendable {
    /// The interval of the full sample, in milliseconds. It is fixed, not a setting.
    public static let fullSampleInterval: Int64 = 60_000

    public var mode: SendMode
    private var lastSent: [String: TelemetryValue] = [:]
    private var lastFullSample: Int64?
    private var fullSampleDue = true

    public init(mode: SendMode = .onChange) {
        self.mode = mode
    }

    /// Call when the selection changes. The next tick then sends a full sample.
    public mutating func selectionDidChange() {
        fullSampleDue = true
    }

    /// Returns the sample to send for the values measured at `ts`, or nil if there is nothing to send.
    /// Values that are not available are simply missing from `measured`.
    public mutating func sample(at ts: Int64, measured: [String: TelemetryValue]) -> Sample? {
        var rounded: [String: TelemetryValue] = [:]
        for (key, value) in measured where value.isSendable {
            rounded[key] = Self.round(value, key: key)
        }

        let full: Bool
        switch mode {
        case .everyTick:
            full = true
        case .onChange:
            full = fullSampleDue
                || lastFullSample.map { ts - $0 >= Self.fullSampleInterval } ?? true
        }

        let values = full ? rounded : rounded.filter { lastSent[$0.key] != $0.value }
        guard !values.isEmpty else { return nil }

        if full {
            lastFullSample = ts
            fullSampleDue = false
        }
        lastSent.merge(values) { _, new in new }
        return Sample(ts: ts, values: values)
    }

    /// Rounds a number to the resolution of its key. Other values stay as they are.
    public static func round(_ value: TelemetryValue, key: String) -> TelemetryValue {
        guard case .number(let number) = value, let resolution = Catalog.resolution(ofValueKey: key) else {
            return value
        }
        return .number(resolution.round(number))
    }
}

/// How a value is measured (see `docs/spec/sensors.md`, Sampling).
public enum ValueKind: Sendable {
    /// One value at every tick of the send rate.
    case sampled
    /// Measured continuously; mean, minimum, and maximum are sent at every tick.
    case aggregated
    /// Sent when it is measured.
    case event
}

/// The smallest unit of the sensor selection.
public struct CatalogItem: Hashable, Sendable, Identifiable {
    public let key: String
    public let groupKey: String
    /// The keys of the values. For an aggregated item these are the means; the keys with
    /// `Min` and `Max` are added to each.
    public let valueKeys: [String]
    public let unit: String
    /// Nil if the value is not a number.
    public let resolution: Resolution?
    public let kind: ValueKind

    public var id: String { key }

    /// All keys this item sends, including `Min` and `Max` of aggregated values.
    public var sentKeys: [String] {
        guard kind == .aggregated else { return valueKeys }
        return valueKeys.flatMap { [$0, $0 + "Min", $0 + "Max"] }
    }
}

/// A group of items. The user switches whole groups on and off.
public struct CatalogGroup: Hashable, Sendable, Identifiable {
    public let key: String
    public let items: [CatalogItem]

    public var id: String { key }
}

/// The catalog of `docs/spec/sensors.md`, in its order.
public enum Catalog {
    public static let groups: [CatalogGroup] = [
        group("motion", [
            ("accel", ["accelX", "accelY", "accelZ"], "m/s²", -2, .aggregated),
            ("accelMagnitude", ["accelMagnitude"], "m/s²", -2, .aggregated),
            ("gyro", ["gyroX", "gyroY", "gyroZ"], "rad/s", -3, .aggregated),
            ("mag", ["magX", "magY", "magZ"], "µT", -1, .sampled),
            ("orientation", ["roll", "pitch", "yaw"], "°", -1, .sampled),
        ]),
        group("environment", [
            ("pressure", ["pressure"], "hPa", -1, .sampled),
            ("light", ["light"], "lx", 0, .sampled),
        ]),
        group("location", [
            ("position", ["latitude", "longitude"], "°", -5, .sampled),
            ("altitude", ["altitude"], "m", -1, .sampled),
            ("speed", ["speed"], "km/h", -1, .sampled),
            ("course", ["course"], "°", 0, .sampled),
            ("locationAccuracy", ["locationAccuracy"], "m", 0, .sampled),
        ]),
        group("activity", [
            ("steps", ["steps"], "count", 0, .sampled),
            ("activityType", ["activityType"], "", nil, .event),
        ]),
        group("device", [
            ("batteryLevel", ["batteryLevel"], "", -2, .sampled),
            ("charging", ["charging"], "", nil, .sampled),
            ("network", ["network"], "", nil, .sampled),
            ("thermalState", ["thermalState"], "", nil, .sampled),
            ("powerSaving", ["powerSaving"], "", nil, .sampled),
            ("cellularSignal", ["cellularSignal"], "dBm", 0, .sampled),
            ("dataVolume", ["dataMobileToday", "dataWifiToday", "dataMobileMonth", "dataWifiMonth"], "B", 3, .sampled),
        ]),
        group("sound", [
            ("soundLevel", ["soundLevel"], "dB", 0, .sampled),
        ]),
        group("health", [
            ("heartRate", ["heartRate"], "1/min", 0, .event),
            ("bodyTemperature", ["bodyTemperature"], "°C", -1, .event),
            ("oxygenSaturation", ["oxygenSaturation"], "%", 0, .event),
            ("respiratoryRate", ["respiratoryRate"], "1/min", 0, .event),
        ]),
        group("test", [
            ("testCounter", ["testCounter"], "count", 0, .sampled),
            ("testSine", ["testSine"], "", -3, .sampled),
        ]),
    ]

    /// All items in catalog order.
    public static let items: [CatalogItem] = groups.flatMap(\.items)

    public static func group(key: String) -> CatalogGroup? {
        groupsByKey[key]
    }

    public static func item(key: String) -> CatalogItem? {
        itemsByKey[key]
    }

    /// The resolution of a sent key, including the `Min` and `Max` keys of aggregated values.
    /// Nil for values that are not numbers and for unknown keys.
    public static func resolution(ofValueKey key: String) -> Resolution? {
        resolutionsByValueKey[key]
    }

    private static let groupsByKey = Dictionary(uniqueKeysWithValues: groups.map { ($0.key, $0) })
    private static let itemsByKey = Dictionary(uniqueKeysWithValues: items.map { ($0.key, $0) })
    private static let resolutionsByValueKey: [String: Resolution] = {
        var result: [String: Resolution] = [:]
        for item in items {
            guard let resolution = item.resolution else { continue }
            for key in item.sentKeys { result[key] = resolution }
        }
        return result
    }()

    private static func group(
        _ key: String,
        _ items: [(String, [String], String, Int?, ValueKind)]
    ) -> CatalogGroup {
        CatalogGroup(key: key, items: items.map { item in
            CatalogItem(
                key: item.0,
                groupKey: key,
                valueKeys: item.1,
                unit: item.2,
                resolution: item.3.map(Resolution.init(exponent:)),
                kind: item.4
            )
        })
    }
}

import Foundation
import SensorCore

/// The settings of connection and transmission (see `docs/spec/configuration.md`). They survive a restart.
struct TransmissionSettings: Codable, Hashable {
    static let sendRates = 1...3600

    /// The wish to be connected.
    var connected = false
    var transmitting = false
    /// Seconds between two ticks.
    var sendRate = 2
    var sendMode = SendMode.onChange
    /// The sensor selection as written in the specification, for example `device,location`.
    var sensors = "device,location"
    var dashboard: String?
    /// Keys of the settings that optiCLOUD manages through a shared attribute: `sendRate`, `sensors`, `dashboard`.
    var managed: Set<String> = []

    var selection: Selection { Selection(parsing: sensors) ?? .default }

    private static let defaultsKey = "transmissionSettings"

    static func load(from defaults: UserDefaults) -> TransmissionSettings {
        defaults.data(forKey: defaultsKey).flatMap { try? JSONDecoder().decode(Self.self, from: $0) } ?? .init()
    }

    func save(to defaults: UserDefaults) {
        defaults.set(try? JSONEncoder().encode(self), forKey: Self.defaultsKey)
    }
}

extension TelemetryValue {
    /// The value as it is written in a payload, for display.
    var text: String {
        switch self {
        case .number(let value): JSONValue.number(value).jsonText
        case .bool(let value): value ? "true" : "false"
        case .string(let value): JSONValue.string(value).jsonText
        }
    }
}

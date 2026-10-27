import ActivityKit
import Foundation

/// The Live Activity while the phone sends (see `docs/spec/connection.md`, Status outside the app). The app starts,
/// updates, and ends it; the widget extension draws it.
nonisolated struct SendingAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: Phase
        /// The samples in the offline queue.
        var waiting: Int
    }

    enum Phase: String, Codable, Hashable {
        /// Connected; the values go out.
        case sending
        /// Not connected; the values wait in the offline queue.
        case waiting
        /// The server refused the device; the user has to act in the app.
        case refused

        var title: LocalizedStringResource {
            switch self {
            case .sending: LocalizedStringResource("Sending", table: "Shared")
            case .waiting: LocalizedStringResource("Waiting for a Connection", table: "Shared")
            case .refused: LocalizedStringResource("Refused by optiCLOUD", table: "Shared")
            }
        }

        var symbol: String {
            switch self {
            case .sending: "dot.radiowaves.left.and.right"
            case .waiting: "clock.arrow.circlepath"
            case .refused: "xmark.octagon.fill"
            }
        }
    }

    let deviceName: String
    /// Since when transmission is on.
    let since: Date
}

/// State that the app shares with its widget extension through the app group.
nonisolated enum SharedState {
    /// The kind of the control in Control Center.
    static let sendingControlKind = "ch.optimeas.opticloudsensor.send"

    private static var defaults: UserDefaults? {
        (Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String).flatMap(UserDefaults.init(suiteName:))
    }

    /// Transmission is switched on in the app.
    static var isTransmitting: Bool {
        get { defaults?.bool(forKey: "isTransmitting") ?? false }
        set { defaults?.set(newValue, forKey: "isTransmitting") }
    }
}

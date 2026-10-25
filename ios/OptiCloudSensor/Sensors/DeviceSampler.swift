import Foundation
import Network
import SensorCore
import UIKit

/// The sampled values of the group `device` (see `docs/spec/sensors.md`, Catalog).
///
/// `cellularSignal` has no public interface on iOS, and `dataVolume` is not counted yet, so neither is offered.
final class DeviceSampler {
    /// The items of the group this phone offers.
    static let offered: Set<String> = ["batteryLevel", "charging", "network", "thermalState", "powerSaving"]

    private let pathMonitor = NWPathMonitor()
    private var network = "none"

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let network = Self.network(of: path)
            Task { @MainActor in self?.network = network }
        }
        pathMonitor.start(queue: .main)
    }

    deinit {
        pathMonitor.cancel()
    }

    /// The current values. A value that is not available is missing.
    func measure() -> [String: TelemetryValue] {
        var values: [String: TelemetryValue] = [
            "network": .string(network),
            "thermalState": .string(Self.name(of: ProcessInfo.processInfo.thermalState)),
            "powerSaving": .bool(ProcessInfo.processInfo.isLowPowerModeEnabled),
        ]
        let device = UIDevice.current
        if device.batteryLevel >= 0 {
            values["batteryLevel"] = .number(Double(device.batteryLevel))
        }
        switch device.batteryState {
        case .charging, .full: values["charging"] = .bool(true)
        case .unplugged: values["charging"] = .bool(false)
        case .unknown: break
        @unknown default: break
        }
        return values
    }

    private nonisolated static func network(of path: NWPath) -> String {
        guard path.status == .satisfied else { return "none" }
        if path.usesInterfaceType(.wifi) { return "wifi" }
        if path.usesInterfaceType(.cellular) { return "cellular" }
        return "other"
    }

    private static func name(of state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "serious"
        case .critical: "critical"
        @unknown default: "nominal"
        }
    }
}

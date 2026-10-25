import CoreMotion
import Foundation
import SensorCore

/// The values of the group `environment` (see `docs/spec/sensors.md`, Catalog).
///
/// iOS has no public interface for the ambient light, so `light` is not offered.
final class EnvironmentSampler {
    /// The items of the group this phone offers.
    static let offered: Set<String> = CMAltimeter.isRelativeAltitudeAvailable() ? ["pressure"] : []

    private let altimeter = CMAltimeter()
    private var pressure: Double?
    private var running = false

    func start() {
        guard !running, CMAltimeter.isRelativeAltitudeAvailable() else { return }
        running = true
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            // Core Motion gives kPa, the catalog hPa.
            let pressure = data.pressure.doubleValue * 10
            MainActor.assumeIsolated { self?.pressure = pressure }
        }
    }

    func stop() {
        altimeter.stopRelativeAltitudeUpdates()
        running = false
        pressure = nil
    }

    func measure() -> [String: TelemetryValue] {
        pressure.map { ["pressure": .number($0)] } ?? [:]
    }
}

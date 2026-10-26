import CoreMotion
import Foundation
import SensorCore

/// The values of the group `environment` (see `docs/spec/sensors.md`, Catalog).
///
/// iOS has no public interface for the ambient light, so `light` is not offered. A pressure older than the maximum
/// age is left out (see `docs/spec/sensors.md`, Age of values).
final class EnvironmentSampler {
    /// The items of the group this phone offers.
    static let offered: Set<String> = CMAltimeter.isRelativeAltitudeAvailable() ? ["pressure"] : []

    private lazy var altimeter = CMAltimeter()
    private var pressure: (value: Double, date: Date)?
    private var running = false

    func start() {
        guard !running, CMAltimeter.isRelativeAltitudeAvailable() else { return }
        running = true
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            // Core Motion gives kPa, the catalog hPa.
            let pressure = data.pressure.doubleValue * 10
            MainActor.assumeIsolated { self?.pressure = (pressure, Date()) }
        }
    }

    func stop() {
        // Calling Core Motion while it is not running can already ask for the permission.
        guard running else { return }
        altimeter.stopRelativeAltitudeUpdates()
        running = false
        pressure = nil
    }

    func measure(now: Date, maxAge: TimeInterval) -> [String: TelemetryValue] {
        guard let pressure, now.timeIntervalSince(pressure.date) <= maxAge else { return [:] }
        return ["pressure": .number(pressure.value)]
    }
}

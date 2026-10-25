import CoreMotion
import Foundation
import SensorCore

/// The values of the group `motion` (see `docs/spec/sensors.md`, Catalog).
///
/// Acceleration and rotation rate are measured at 50 Hz and aggregated between two ticks; the magnetic field and
/// the orientation are the latest values at a tick. Core Motion reports the acceleration in g with the opposite
/// sign of the catalog, so it is converted.
final class MotionSampler {
    /// The items of the group this phone offers.
    static let offered: Set<String> = {
        let manager = CMMotionManager()
        var items: Set<String> = []
        if manager.isDeviceMotionAvailable { items.formUnion(["accel", "accelMagnitude", "gyro"]) }
        if manager.isMagnetometerAvailable,
           CMMotionManager.availableAttitudeReferenceFrames().contains(.xMagneticNorthZVertical) {
            items.formUnion(["mag", "orientation"])
        }
        return items
    }()

    private static let standardGravity = 9.80665

    private let manager = CMMotionManager()
    private var aggregates: [String: Aggregate] = [:]
    private var latest: CMDeviceMotion?

    var isRunning: Bool { manager.isDeviceMotionActive }

    func start() {
        guard !manager.isDeviceMotionActive, manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 50
        let frame: CMAttitudeReferenceFrame = Self.offered.contains("orientation") ? .xMagneticNorthZVertical : .xArbitraryZVertical
        manager.startDeviceMotionUpdates(using: frame, to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            MainActor.assumeIsolated { self?.add(motion) }
        }
    }

    func stop() {
        guard manager.isDeviceMotionActive else { return }
        manager.stopDeviceMotionUpdates()
        aggregates = [:]
        latest = nil
    }

    /// The values since the previous call. Starts the next aggregation period.
    func measure() -> [String: TelemetryValue] {
        var values: [String: TelemetryValue] = [:]
        for (key, aggregate) in aggregates {
            values.merge(aggregate.values(key: key, resolution: nil)) { $1 }
        }
        aggregates = [:]
        guard let motion = latest else { return values }

        let field = motion.magneticField
        let calibrated = field.accuracy != .uncalibrated
        if calibrated {
            values["magX"] = .number(field.field.x)
            values["magY"] = .number(field.field.y)
            values["magZ"] = .number(field.field.z)
        }
        let gravity = Self.catalogAxes(motion.gravity)
        let magnetic = calibrated ? (field.field.x, field.field.y, field.field.z) : nil
        values.merge(Orientation.angles(gravity: gravity, magneticField: magnetic)) { $1 }
        return values
    }

    private func add(_ motion: CMDeviceMotion) {
        latest = motion
        let total = CMAcceleration(
            x: motion.gravity.x + motion.userAcceleration.x,
            y: motion.gravity.y + motion.userAcceleration.y,
            z: motion.gravity.z + motion.userAcceleration.z
        )
        let accel = Self.catalogAxes(total)
        aggregates["accelX", default: Aggregate()].add(accel.x)
        aggregates["accelY", default: Aggregate()].add(accel.y)
        aggregates["accelZ", default: Aggregate()].add(accel.z)
        aggregates["accelMagnitude", default: Aggregate()].add(Aggregate.magnitude(x: accel.x, y: accel.y, z: accel.z))
        let rate = motion.rotationRate
        aggregates["gyroX", default: Aggregate()].add(rate.x)
        aggregates["gyroY", default: Aggregate()].add(rate.y)
        aggregates["gyroZ", default: Aggregate()].add(rate.z)
    }

    /// Core Motion: in g, about -1 on z when the phone lies flat with the screen up. Catalog: m/s², about +9.81.
    private static func catalogAxes(_ a: CMAcceleration) -> (x: Double, y: Double, z: Double) {
        (-a.x * standardGravity, -a.y * standardGravity, -a.z * standardGravity)
    }
}

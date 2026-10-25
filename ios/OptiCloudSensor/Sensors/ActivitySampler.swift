import CoreMotion
import Foundation
import SensorCore

/// The values of the group `activity` (see `docs/spec/sensors.md`, Catalog).
///
/// `steps` counts from midnight, local time. `activityType` is an event value: it is reported when it changes,
/// with the time the system detected it.
final class ActivitySampler {
    /// The items of the group this phone offers.
    static let offered: Set<String> = {
        var items: Set<String> = []
        if CMPedometer.isStepCountingAvailable() { items.insert("steps") }
        if CMMotionActivityManager.isActivityAvailable() { items.insert("activityType") }
        return items
    }()

    /// Called with the type of a new activity and when it began.
    var activityChanged: ((String, Date) -> Void)?

    private let pedometer = CMPedometer()
    private let activities = CMMotionActivityManager()
    private var steps: Int?
    private var countingSince: Date?
    private var lastType: String?
    private var running = false

    func start() {
        guard !running else { return }
        running = true
        startCounting()
        if CMMotionActivityManager.isActivityAvailable() {
            activities.startActivityUpdates(to: .main) { [weak self] activity in
                guard let activity else { return }
                MainActor.assumeIsolated { self?.received(activity) }
            }
        }
    }

    func stop() {
        pedometer.stopUpdates()
        activities.stopActivityUpdates()
        running = false
        steps = nil
        countingSince = nil
        lastType = nil
    }

    func measure() -> [String: TelemetryValue] {
        // A new day starts the count again.
        if running, let countingSince, !Calendar.current.isDateInToday(countingSince) {
            pedometer.stopUpdates()
            steps = nil
            startCounting()
        }
        return steps.map { ["steps": .number(Double($0))] } ?? [:]
    }

    private func startCounting() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        let midnight = Calendar.current.startOfDay(for: Date())
        countingSince = midnight
        pedometer.startUpdates(from: midnight, withHandler: Self.handler { [weak self] steps in self?.steps = steps })
    }

    /// The pedometer calls its handler on a queue of its own, not on the main actor.
    private nonisolated static func handler(_ update: @escaping @MainActor (Int) -> Void) -> CMPedometerHandler {
        { data, _ in
            guard let steps = data?.numberOfSteps.intValue else { return }
            Task { @MainActor in update(steps) }
        }
    }

    private func received(_ activity: CMMotionActivity) {
        let type = Self.type(of: activity)
        guard type != lastType else { return }
        lastType = type
        activityChanged?(type, activity.startDate)
    }

    /// The catalog names the most specific activity; a car that stands still is still `automotive`.
    private static func type(of activity: CMMotionActivity) -> String {
        if activity.automotive { return "automotive" }
        if activity.cycling { return "cycling" }
        if activity.running { return "running" }
        if activity.walking { return "walking" }
        if activity.stationary { return "stationary" }
        return "unknown"
    }
}

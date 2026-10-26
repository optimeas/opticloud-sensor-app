import CoreLocation
import Foundation
import Observation
import SensorCore

/// The sampled values of the group `location` (see `docs/spec/sensors.md`, Catalog).
///
/// With the permission "Always" and the location background mode, the updates go on in the background, and the app
/// with them (see `ios/CLAUDE.md`, Architecture). The system shows the location arrow while updates arrive.
/// A position older than the maximum age is not sent (see `docs/spec/sensors.md`, Age of values).
@Observable
final class LocationSampler: NSObject {
    /// The items of the group this phone offers.
    static let offered: Set<String> = ["position", "altitude", "speed", "course", "locationAccuracy"]

    private(set) var authorization: CLAuthorizationStatus
    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private var updating = false
    @ObservationIgnored private var latest: CLLocation?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var wanted = false

    /// Called when the updates start or stop, or Core Location reports a problem, for the log of the test area.
    @ObservationIgnored var logged: ((TestLog.Entry.Kind, String, String?) -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        // Without this, Core Location pauses the updates when the phone stands still, and iOS suspends the app.
        manager.pausesLocationUpdatesAutomatically = false
    }

    var isRunning: Bool { updating }

    /// Starts the location updates, and asks for the permission first if it has not been asked for.
    func start() {
        wanted = true
        switch authorization {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            askForAlwaysOnce()
            startUpdates()
        case .authorizedAlways:
            startUpdates()
        default:
            break
        }
    }

    func stop() {
        wanted = false
        stopUpdates()
    }

    /// The current values. Values the location does not have are missing, and so is a position older than `maxAge`.
    func measure(now: Date, maxAge: TimeInterval) -> [String: TelemetryValue] {
        guard let location = latest, location.horizontalAccuracy >= 0,
              now.timeIntervalSince(location.timestamp) <= maxAge
        else { return [:] }
        var values: [String: TelemetryValue] = [
            "latitude": .number(location.coordinate.latitude),
            "longitude": .number(location.coordinate.longitude),
            "locationAccuracy": .number(location.horizontalAccuracy),
        ]
        if location.verticalAccuracy >= 0 {
            values["altitude"] = .number(location.altitude)
        }
        if location.speed >= 0 && location.speedAccuracy >= 0 {
            values["speed"] = .number(location.speed * 3.6)
        }
        if location.course >= 0 && location.courseAccuracy >= 0 {
            values["course"] = .number(location.course)
        }
        return values
    }

    private func startUpdates() {
        guard !updating else { return }
        updating = true
        // Only with "Always" may the updates, and the app with them, go on in the background.
        manager.allowsBackgroundLocationUpdates = authorization == .authorizedAlways
        manager.startUpdatingLocation()
        logged?(.location, String(localized: "Location updates started"), authorization == .authorizedAlways ? "Always" : "When in use")
    }

    private func stopUpdates() {
        guard updating else { return }
        updating = false
        manager.stopUpdatingLocation()
        latest = nil
        logged?(.location, String(localized: "Location updates stopped"), nil)
    }

    /// The system shows the question for "Always" only once; after that the user changes it in Settings.
    private func askForAlwaysOnce() {
        guard !defaults.bool(forKey: "askedForAlwaysLocation") else { return }
        defaults.set(true, forKey: "askedForAlwaysLocation")
        manager.requestAlwaysAuthorization()
    }

    private func authorizationChanged(_ status: CLAuthorizationStatus) {
        authorization = status
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            guard wanted else { break }
            if updating {
                // A change between "When in use" and "Always" changes whether the updates may go on in the background.
                manager.allowsBackgroundLocationUpdates = status == .authorizedAlways
            } else {
                start()
            }
        case .denied, .restricted:
            stopUpdates()
        default:
            break
        }
    }
}

extension LocationSampler: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.authorizationChanged(status) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in if self.updating { self.latest = location } }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // `locationUnknown` is temporary; Core Location keeps trying.
        guard (error as? CLError)?.code != .locationUnknown else { return }
        let text = error.localizedDescription
        Task { @MainActor in self.logged?(.problem, String(localized: "Location problem"), text) }
    }
}

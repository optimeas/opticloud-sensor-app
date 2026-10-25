import CoreLocation
import Foundation
import Observation
import SensorCore

/// The sampled values of the group `location` (see `docs/spec/sensors.md`, Catalog).
///
/// While the location is in use, the app keeps a background activity session, so that it goes on sampling and
/// sending in the background (see `ios/CLAUDE.md`, Architecture). The system shows this to the user.
@Observable
final class LocationSampler: NSObject {
    /// The items of the group this phone offers.
    static let offered: Set<String> = ["position", "altitude", "speed", "course", "locationAccuracy"]

    private(set) var authorization: CLAuthorizationStatus
    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private var updates: Task<Void, Never>?
    @ObservationIgnored private var backgroundSession: CLBackgroundActivitySession?
    @ObservationIgnored private var latest: CLLocation?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var wanted = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    var isRunning: Bool { updates != nil }

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
        updates?.cancel()
        updates = nil
        backgroundSession?.invalidate()
        backgroundSession = nil
        latest = nil
    }

    /// The current values. Values the location does not have are missing.
    func measure() -> [String: TelemetryValue] {
        guard let location = latest, location.horizontalAccuracy >= 0 else { return [:] }
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
        guard updates == nil else { return }
        // Created while the app is in use, the session lets the updates go on in the background.
        backgroundSession = CLBackgroundActivitySession()
        updates = Task { [weak self] in
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if let location = update.location { self?.latest = location }
                }
            } catch {
                // The updates ended, for example because the permission was withdrawn.
            }
        }
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
            if wanted { start() }
        case .denied, .restricted:
            updates?.cancel()
            updates = nil
            latest = nil
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
}

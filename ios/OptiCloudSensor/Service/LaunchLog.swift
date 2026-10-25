import Foundation
import UIKit

/// The last launches of the app, so that the diagnosis shows when the system started it in the background and why.
/// Kept in UserDefaults, because a launch in the background is never seen on screen.
enum LaunchLog {
    struct Entry: Codable, Identifiable {
        var id: Date { date }
        let date: Date
        /// The app came to the screen after the launch. A launch by the system in the background does not.
        var opened = false
        /// Core Location started the app to deliver location updates.
        let byLocation: Bool
        /// Transmission was switched on at the launch.
        let transmitting: Bool
    }

    static let capacity = 20
    private static let key = "launchLog"

    /// The newest entry first.
    static func entries(in defaults: UserDefaults = .standard) -> [Entry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    static func record(_ entry: Entry, in defaults: UserDefaults = .standard) {
        save(Array(([entry] + entries(in: defaults)).prefix(capacity)), in: defaults)
    }

    /// Marks the newest launch as opened.
    static func markOpened(in defaults: UserDefaults = .standard) {
        var entries = entries(in: defaults)
        guard !entries.isEmpty, !entries[0].opened else { return }
        entries[0].opened = true
        save(entries, in: defaults)
    }

    private static func save(_ entries: [Entry], in defaults: UserDefaults) {
        defaults.set(try? JSONEncoder().encode(entries), forKey: key)
    }
}

/// Records each launch with the reason the system gives, and whether the app came to the screen.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        LaunchLog.record(LaunchLog.Entry(
            date: .now,
            // The key is deprecated in favor of handling the updates after launch, but it still tells the reason.
            byLocation: launchOptions?[UIApplication.LaunchOptionsKey(rawValue: "UIApplicationLaunchOptionsLocationKey")] != nil,
            transmitting: TransmissionSettings.load(from: .standard).transmitting
        ))
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { LaunchLog.markOpened() }
        }
        return true
    }
}

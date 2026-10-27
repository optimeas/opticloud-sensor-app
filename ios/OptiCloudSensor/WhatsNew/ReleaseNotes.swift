import Foundation
import SensorCore

/// The versions of the app with their highlights and changes, newest first (see `docs/spec/whats-new.md`).
/// `ios/CHANGELOG.md` and the manual page "What's new" say the same.
enum ReleaseNotes {
    /// The version of the app the user sees, without the build number.
    static let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    /// The releases whose highlights the screen "What's New" shows after the given last seen version, newest first.
    static func new(since lastSeen: String?) -> [Release] {
        let withHighlights = all.filter { !$0.highlights.isEmpty }
        let versions = StartScreen.versions(lastSeen: lastSeen, version: currentVersion, withHighlights: withHighlights.map(\.version))
        return versions.compactMap { version in withHighlights.first { $0.version == version } }
    }

    /// The features on the welcome screen.
    static let welcome: [Highlight] = [
        Highlight(
            symbol: "gauge.with.dots.needle.67percent",
            title: LocalizedStringResource("Measure What Matters", comment: "Feature on the welcome screen"),
            text: LocalizedStringResource("Motion, location, air pressure, sound, and more: you choose what your iPhone measures.", comment: "Feature on the welcome screen")
        ),
        Highlight(
            symbol: "icloud.and.arrow.up.fill",
            title: LocalizedStringResource("Live in optiCLOUD", comment: "Feature on the welcome screen"),
            text: LocalizedStringResource("The values go to your device in optiCLOUD, also with the screen locked. Without a network, they wait and follow later.", comment: "Feature on the welcome screen")
        ),
        Highlight(
            symbol: "square.and.pencil",
            title: LocalizedStringResource("Notes and Favorites", comment: "Feature on the welcome screen"),
            text: LocalizedStringResource("Note what happens with a tap or with Siri, and open your dashboards right in the app.", comment: "Feature on the welcome screen")
        ),
        Highlight(
            symbol: "lock.shield.fill",
            title: LocalizedStringResource("Open and Private", comment: "Feature on the welcome screen"),
            text: LocalizedStringResource("The app sends only what you choose, to the device you choose. Its code is open source.", comment: "Feature on the welcome screen")
        ),
    ]

    static let all: [Release] = [
        Release(
            version: "0.9.0", build: nil, date: day(2026, 10, 28),
            highlights: [
                Highlight(
                    symbol: "lock.iphone",
                    title: LocalizedStringResource("Sending at a Glance", comment: "Highlight of version 0.9"),
                    text: LocalizedStringResource("On the Lock Screen and in the Dynamic Island you see whether the app sends and how many values wait. One tap stops it.", comment: "Highlight of version 0.9")
                ),
                Highlight(
                    symbol: "switch.2",
                    title: LocalizedStringResource("In Control Center", comment: "Highlight of version 0.9"),
                    text: LocalizedStringResource("Start and stop sending from Control Center, the Lock Screen, or the Action button.", comment: "Highlight of version 0.9")
                ),
            ],
            changes: [
                Change(.new, LocalizedStringResource("While the app sends, a Live Activity on the Lock Screen and in the Dynamic Island shows the state, the device, and the waiting values, with a button to stop.", comment: "Change in version 0.9")),
                Change(.new, LocalizedStringResource("The control “Send to optiCLOUD” starts and stops sending from Control Center, the Lock Screen, or the Action button.", comment: "Change in version 0.9")),
                Change(.improved, LocalizedStringResource("After an update over several versions, What’s New shows the highlights of each of them.", comment: "Change in version 0.9")),
            ]
        ),
        Release(
            version: "0.8.0", build: nil, date: day(2026, 10, 27),
            highlights: [
                Highlight(
                    symbol: "star.fill",
                    title: LocalizedStringResource("Favorites", comment: "Highlight of version 0.8"),
                    text: LocalizedStringResource("Your dashboards and favorites from optiCLOUD in one tab, opened without signing in again.", comment: "Highlight of version 0.8")
                ),
                Highlight(
                    symbol: "square.and.pencil",
                    title: LocalizedStringResource("Quick Note", comment: "Highlight of version 0.8"),
                    text: LocalizedStringResource("A note in seconds, with a tap or with Siri. Without a network, it waits and is sent later.", comment: "Highlight of version 0.8")
                ),
                Highlight(
                    symbol: "tram.fill",
                    title: LocalizedStringResource("Steady on the Move", comment: "Highlight of version 0.8"),
                    text: LocalizedStringResource("The app no longer stops when the mobile network drops, for example on a train.", comment: "Highlight of version 0.8")
                ),
            ],
            changes: [
                Change(.new, LocalizedStringResource("The tab Favorites shows the default dashboard, your favorites from the web application, and favorites of your own, and opens them signed in.", comment: "Change in version 0.8")),
                Change(.new, LocalizedStringResource("Quick note from the live view. The title is optional; without one, the note takes the first line of the text.", comment: "Change in version 0.8")),
                Change(.new, LocalizedStringResource("Siri and the Shortcuts app: “New optiCLOUD Note” saves a dictated note without opening the app.", comment: "Change in version 0.8")),
                Change(.new, LocalizedStringResource("Notes wait without a network or sign-in and are sent later. The Diagnosis tab shows them.", comment: "Change in version 0.8")),
                Change(.new, LocalizedStringResource("Welcome screen, this overview of what is new, and the version history.", comment: "Change in version 0.8")),
                Change(.fixed, LocalizedStringResource("The app no longer stops when the connection drops while data arrives.", comment: "Change in version 0.8")),
                Change(.fixed, LocalizedStringResource("The tenant stays shown after choosing a device.", comment: "Change in version 0.8")),
                Change(.fixed, LocalizedStringResource("The list of devices shows only the devices of the chosen project.", comment: "Change in version 0.8")),
            ]
        ),
        Release(
            version: "0.1.0", build: "74", date: day(2026, 10, 26),
            highlights: [],
            changes: [
                Change(.improved, LocalizedStringResource("Sending in the background goes on with the screen locked, with fresh positions.", comment: "Change in version 0.1, build 74")),
                Change(.new, LocalizedStringResource("Test signal to check in optiCLOUD that every value has arrived.", comment: "Change in version 0.1, build 74")),
                Change(.improved, LocalizedStringResource("The diagnosis log is kept when the app restarts.", comment: "Change in version 0.1, build 74")),
                Change(.fixed, LocalizedStringResource("The log no longer shows the identifier of the installation.", comment: "Change in version 0.1, build 74")),
            ]
        ),
        Release(
            version: "0.1.0", build: "66", date: day(2026, 10, 26),
            highlights: [],
            changes: [
                Change(.new, LocalizedStringResource("Sign in to optiCLOUD and choose the device of this phone.", comment: "Change in version 0.1, build 66")),
                Change(.new, LocalizedStringResource("Sensors for motion, environment, location, activity, the device, and sound.", comment: "Change in version 0.1, build 66")),
                Change(.new, LocalizedStringResource("Sending in the background and an offline queue that delivers the values later.", comment: "Change in version 0.1, build 66")),
                Change(.new, LocalizedStringResource("Commands and settings from optiCLOUD, and the data volume of the app.", comment: "Change in version 0.1, build 66")),
                Change(.new, LocalizedStringResource("Diagnosis with log and test values, in five languages, with a user manual.", comment: "Change in version 0.1, build 66")),
            ]
        ),
    ]

    private static func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        // Noon UTC, so that the day is the same in every time zone of Europe.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}

/// A version of the app.
struct Release: Identifiable {
    let version: String
    /// The build, when the version had more than one.
    let build: String?
    let date: Date
    /// What matters most to the user, for the screen "What's New".
    let highlights: [Highlight]
    let changes: [Change]

    var id: String { "\(version) \(build ?? "")" }
}

/// A feature or change with a symbol, a title, and one sentence.
struct Highlight: Identifiable {
    let symbol: String
    let title: LocalizedStringResource
    let text: LocalizedStringResource

    var id: String { title.key }
}

struct Change: Identifiable {
    enum Kind {
        case new, improved, fixed
    }

    let kind: Kind
    let text: LocalizedStringResource

    init(_ kind: Kind, _ text: LocalizedStringResource) {
        self.kind = kind
        self.text = text
    }

    var id: String { text.key }
}

import Foundation
import Observation

/// What the test area shows about the communication: commands and their answers, changes of shared attributes,
/// values the app could not use, and the reasons of the connection state. It is kept in memory only.
@Observable
final class TestLog {
    struct Entry: Identifiable {
        enum Kind {
            case command
            case sharedAttribute
            case problem
            case connection
            case sent
        }

        let id = UUID()
        let date: Date
        let kind: Kind
        let title: String
        let detail: String?
    }

    static let capacity = 200

    /// The newest entry first.
    private(set) var entries: [Entry] = []

    func add(_ kind: Entry.Kind, _ title: String, detail: String? = nil) {
        entries.insert(Entry(date: .now, kind: kind, title: title, detail: detail), at: 0)
        if entries.count > Self.capacity { entries.removeLast(entries.count - Self.capacity) }
    }

    func clear() {
        entries = []
    }
}

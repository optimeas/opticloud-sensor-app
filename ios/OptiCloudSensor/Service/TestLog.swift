import Foundation
import Observation

/// What the test area shows about the communication: commands and their answers, changes of shared attributes,
/// values the app could not use, the reasons of the connection state, the location updates, the starts of the app,
/// and the times it went to the background or was paused.
///
/// The log is kept in a file, so that it survives a new start of the app, for example after iOS ended it in the
/// background. Each entry is one line of JSON, appended as it happens; a line cut off by a crash is skipped.
@Observable
final class TestLog {
    struct Entry: Identifiable, Codable {
        enum Kind: String, Codable {
            case command
            case sharedAttribute
            case problem
            case connection
            case sent
            case location
            case app
        }

        var id = UUID()
        let date: Date
        let kind: Kind
        let title: String
        let detail: String?

        private enum CodingKeys: String, CodingKey {
            case date, kind, title, detail
        }
    }

    static let capacity = 1000
    /// The file may hold this many more lines than the capacity before it is written again without the oldest.
    private static let slack = 200

    /// The newest entry first.
    private(set) var entries: [Entry] = []
    @ObservationIgnored private let url: URL?
    @ObservationIgnored private var linesInFile = 0

    /// Without a URL the log is kept in memory only.
    init(url: URL? = TestLog.defaultURL) {
        self.url = url
        load()
    }

    static var defaultURL: URL? {
        try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: "log.jsonl")
    }

    func add(_ kind: Entry.Kind, _ title: String, detail: String? = nil) {
        let entry = Entry(date: .now, kind: kind, title: title, detail: detail)
        entries.insert(entry, at: 0)
        if entries.count > Self.capacity { entries.removeLast(entries.count - Self.capacity) }
        if linesInFile >= Self.capacity + Self.slack {
            rewrite()
        } else {
            append(entry)
        }
    }

    func clear() {
        entries = []
        rewrite()
    }

    // MARK: File

    private func load() {
        guard let url, let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        let lines = data.split(separator: UInt8(ascii: "\n"))
        linesInFile = lines.count
        entries = lines.suffix(Self.capacity).compactMap { try? decoder.decode(Entry.self, from: $0) }.reversed()
        // A line cut off by a crash would swallow the next entry appended to it.
        if data.last != UInt8(ascii: "\n") { rewrite() }
    }

    private func append(_ entry: Entry) {
        guard let url, let line = Self.line(entry) else { return }
        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                try Self.write(Data(), to: url)
            }
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
            linesInFile += 1
        } catch {
            // The entry stays in memory; the log in the file misses it.
        }
    }

    private func rewrite() {
        guard let url else { return }
        let data = entries.reversed().compactMap(Self.line).reduce(into: Data()) { $0.append($1) }
        try? Self.write(data, to: url)
        linesInFile = entries.count
    }

    private static func line(_ entry: Entry) -> Data? {
        guard var data = try? JSONEncoder().encode(entry) else { return nil }
        data.append(UInt8(ascii: "\n"))
        return data
    }

    /// The app writes the log in the background with the phone locked, so the file is readable after the first unlock.
    private static func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}

import Foundation

/// The persistent queue of journal entries (see `docs/spec/offline-queue.md`, Journal entries).
///
/// The entries are kept in a JSON file in the order they were saved. The queue never discards an entry by itself.
public actor JournalQueue {
    /// The most entries the queue holds.
    public static let defaultMaxEntries = 500

    /// An entry in the queue with what its note needs.
    public struct Item: Hashable, Codable, Sendable, Identifiable {
        public enum State: Hashable, Codable, Sendable {
            case waiting
            /// The server refused the note; the user sends it again or deletes it.
            case setAside(message: String)
        }

        public let id: UUID
        public let entry: JournalEntry
        /// The device the entry was saved for.
        public let deviceId: String
        /// The user who saved the entry.
        public let userId: String
        public var state: State
    }

    /// Why delivery stopped before the queue was empty.
    public enum Stop: Hashable, Sendable {
        /// Nothing waits for the user of the session any more.
        case done
        /// No network or a temporary problem of the server. Try again later.
        case later(message: String)
        /// There is no session, or it cannot be renewed.
        case signInNeeded
    }

    public struct Delivery: Hashable, Sendable {
        public var delivered: [Item] = []
        public var setAside: [Item] = []
        public var stop: Stop = .done
    }

    public enum QueueError: Error, Hashable {
        case full
    }

    private let url: URL
    private let maxEntries: Int
    private(set) public var items: [Item]

    /// Opens the queue at `url`. A file that cannot be read is kept aside next to it, so that no entry is lost.
    public init(url: URL, maxEntries: Int = defaultMaxEntries) {
        self.url = url
        self.maxEntries = maxEntries
        if let data = try? Data(contentsOf: url) {
            if let items = try? JSONDecoder().decode([Item].self, from: data) {
                self.items = items
            } else {
                try? FileManager.default.moveItem(at: url, to: url.appendingPathExtension("unreadable"))
                self.items = []
            }
        } else {
            self.items = []
        }
    }

    /// Appends an entry at the end.
    @discardableResult
    public func add(_ entry: JournalEntry, deviceId: String, userId: String) throws -> Item {
        guard items.count < maxEntries else { throw QueueError.full }
        let item = Item(id: UUID(), entry: entry, deviceId: deviceId, userId: userId, state: .waiting)
        items.append(item)
        try save()
        return item
    }

    public func remove(id: UUID) throws {
        items.removeAll { $0.id == id }
        try save()
    }

    /// Lets an entry that was set aside wait again, so that the next delivery sends it.
    public func retry(id: UUID) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].state = .waiting
        try save()
    }

    /// Delivers the waiting entries of `userId`, oldest first, one at a time. `send` creates the note of an entry.
    public func deliver(userId: String?, send: @Sendable (Item) async throws -> Void) async -> Delivery {
        var result = Delivery()
        guard let userId else {
            if items.contains(where: { $0.state == .waiting }) { result.stop = .signInNeeded }
            return result
        }
        while let item = items.first(where: { $0.state == .waiting && $0.userId == userId }) {
            do {
                try await send(item)
                items.removeAll { $0.id == item.id }
                result.delivered.append(item)
            } catch {
                switch Self.outcome(of: error) {
                case .later(let message):
                    result.stop = .later(message: message)
                    return result
                case .signInNeeded:
                    result.stop = .signInNeeded
                    return result
                case .setAside(let message):
                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                        items[index].state = .setAside(message: message)
                        result.setAside.append(items[index])
                    }
                }
            }
            try? save()
        }
        return result
    }

    private enum Outcome {
        case later(message: String)
        case signInNeeded
        case setAside(message: String)
    }

    /// The table of `docs/spec/offline-queue.md`, Journal entries, Delivering.
    private static func outcome(of error: Error) -> Outcome {
        let status: Int
        let message: String
        switch error {
        case OptiCloudError.notSignedIn:
            return .signInNeeded
        case OptiCloudError.api(let code, let body):
            status = code
            message = body.message ?? "HTTP \(code)"
        case OptiCloudError.http(let code), OptiCloudError.signInRejected(let code, _):
            status = code
            message = "HTTP \(code)"
        default:
            return .later(message: error.localizedDescription)
        }
        switch status {
        case 401: return .signInNeeded
        case 429, 500...: return .later(message: message)
        default: return .setAside(message: message)
        }
    }

    private func save() throws {
        let data = try JSONEncoder().encode(items)
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }
}

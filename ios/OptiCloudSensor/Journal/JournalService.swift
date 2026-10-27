import Foundation
import Observation
import SensorCore
import UIKit

/// Saves journal entries into their queue and delivers them as notes through the user's session (see
/// `docs/spec/journal.md` and `docs/spec/offline-queue.md`, Journal entries). Works without the user interface, so
/// that the App Shortcut can save an entry without opening the app.
@Observable
final class JournalService {
    enum SaveError: LocalizedError {
        case emptyText, noDevice, notSignedIn, full

        var errorDescription: String? {
            switch self {
            case .emptyText: String(localized: "The note has no text.")
            case .noDevice: String(localized: "Choose the device of this phone in the app first.")
            case .notSignedIn: String(localized: "Sign in to optiCLOUD in the app to write notes.")
            case .full: String(localized: "There are 500 notes waiting to be sent. Send or delete some of them first.")
            }
        }
    }

    /// The entries in the queue, oldest first.
    private(set) var items: [JournalQueue.Item] = []
    /// Why the last delivery stopped.
    private(set) var stop: JournalQueue.Stop = .done
    /// The user of the session at the last delivery.
    private(set) var userId: String?
    /// The form for a new entry is open.
    var isComposing = false

    @ObservationIgnored private let app: AppModel
    @ObservationIgnored private let location: LocationSampler
    @ObservationIgnored private let log: TestLog
    @ObservationIgnored private let queue: JournalQueue
    @ObservationIgnored private var delivery: Task<Void, Never>?
    @ObservationIgnored private var retries: Task<Void, Never>?
    @ObservationIgnored private var scheduledDeliveries = 0
    @ObservationIgnored private var finishedDeliveries = 0

    /// Delivery is tried again this often while entries wait.
    static let retryInterval: Duration = .seconds(60)

    init(app: AppModel, location: LocationSampler, log: TestLog) {
        self.app = app
        self.location = location
        self.log = log
        let folder = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        queue = JournalQueue(url: (folder ?? FileManager.default.temporaryDirectory).appending(path: "journal.json"))
        Task {
            items = await queue.items
            deliver()
        }
        observeForeground()
    }

    /// The entries that wait for delivery.
    var waiting: [JournalQueue.Item] { items.filter { $0.state == .waiting } }
    /// The entries the server refused.
    var setAside: [JournalQueue.Item] { items.filter { $0.state != .waiting } }
    /// The waiting entries of another user than the one of the session.
    var waitingForOtherUser: Int { waiting.filter { userId != nil && $0.userId != userId }.count }

    /// Saves an entry with the moment of saving and, if allowed, the position, and starts its delivery. Returns the
    /// entry in the queue.
    @discardableResult
    func save(title: String, text: String, status: JournalEntry.Status = .created, priority: JournalEntry.Priority = .medium) async throws -> JournalQueue.Item {
        let savedAt = Date()
        var entry = JournalEntry(
            title: title, text: text, status: status, priority: priority,
            savedAt: Int64((savedAt.timeIntervalSince1970 * 1000).rounded()),
            utcOffsetMinutes: TimeZone.current.secondsFromGMT(for: savedAt) / 60
        )
        guard entry.canBeSaved else { throw SaveError.emptyText }
        guard let device = app.device else { throw SaveError.noDevice }
        guard let userId = await app.client?.claims?.userId else { throw SaveError.notSignedIn }
        if let position = await location.position() {
            entry.latitude = position.coordinate.latitude
            entry.longitude = position.coordinate.longitude
        }
        let item: JournalQueue.Item
        do {
            item = try await queue.add(entry, deviceId: device.id, userId: userId)
        } catch JournalQueue.QueueError.full {
            throw SaveError.full
        }
        items = await queue.items
        log.add(.journal, String(localized: "Note saved"), detail: entry.noteName)
        deliver()
        return item
    }

    /// Waits at most `timeout` for the latest delivery, and says whether the entry was delivered.
    func waitForDelivery(of item: JournalQueue.Item, timeout: Duration) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        let ticket = scheduledDeliveries
        while finishedDeliveries < ticket, clock.now < deadline {
            try? await Task.sleep(for: .milliseconds(200))
        }
        return !items.contains { $0.id == item.id }
    }

    /// Delivers the waiting entries. A delivery that is under way finishes first.
    func deliver() {
        let previous = delivery
        scheduledDeliveries += 1
        let ticket = scheduledDeliveries
        delivery = Task {
            await previous?.value
            await deliverNow()
            finishedDeliveries = ticket
        }
    }

    /// Lets an entry the server refused wait again and delivers it.
    func retry(_ item: JournalQueue.Item) {
        Task {
            try? await queue.retry(id: item.id)
            items = await queue.items
            deliver()
        }
    }

    func delete(_ item: JournalQueue.Item) {
        Task {
            try? await queue.remove(id: item.id)
            items = await queue.items
            log.add(.journal, String(localized: "Note deleted"), detail: item.entry.noteName)
        }
    }

    private func deliverNow() async {
        let client = app.client
        userId = await client?.claims?.userId
        let result = await queue.deliver(userId: userId) { item in
            guard let client, let claims = await client.claims?.noteClaims else { throw OptiCloudError.notSignedIn }
            try await client.createNote(NoteRequest(entry: item.entry, claims: claims, deviceId: item.deviceId))
        }
        items = await queue.items
        for item in result.delivered {
            log.add(.sent, String(localized: "Note sent"), detail: item.entry.noteName)
        }
        for item in result.setAside {
            if case .setAside(let message) = item.state {
                log.add(.problem, String(localized: "Note refused"), detail: "\(item.entry.noteName)\n\(message)")
            }
        }
        if result.stop != stop {
            switch result.stop {
            case .later(let message): log.add(.journal, String(localized: "Notes wait for the network"), detail: message)
            case .signInNeeded: log.add(.journal, String(localized: "Notes wait for a sign-in"))
            case .done: break
            }
        }
        stop = result.stop
        scheduleRetries()
    }

    /// While entries of the user wait, delivery is tried again every minute.
    private func scheduleRetries() {
        let pending = waiting.contains { $0.userId == userId }
        if !pending {
            retries?.cancel()
            retries = nil
        } else if retries == nil {
            retries = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: Self.retryInterval)
                    guard !Task.isCancelled, let self else { return }
                    self.deliver()
                }
            }
        }
    }

    private func observeForeground() {
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
                self?.deliver()
            }
        }
    }
}

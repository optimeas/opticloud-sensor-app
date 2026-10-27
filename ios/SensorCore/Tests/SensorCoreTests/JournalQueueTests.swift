import Foundation
import SensorCore
import Synchronization
import Testing

struct JournalQueueTests {
    let url = FileManager.default.temporaryDirectory.appending(path: "journal-\(UUID().uuidString).json")

    func entry(_ text: String) -> JournalEntry {
        JournalEntry(title: "", text: text, savedAt: 1_760_000_000_000, utcOffsetMinutes: 120)
    }

    struct Refused: Error {}

    @Test func entriesSurviveReopening() async throws {
        let queue = JournalQueue(url: url)
        try await queue.add(entry("one"), deviceId: "d1", userId: "u1")
        try await queue.add(entry("two"), deviceId: "d1", userId: "u1")
        let reopened = JournalQueue(url: url)
        #expect(await reopened.items.map(\.entry.text) == ["one", "two"])
    }

    @Test func deliveredOldestFirstAndRemoved() async throws {
        let queue = JournalQueue(url: url)
        try await queue.add(entry("one"), deviceId: "d1", userId: "u1")
        try await queue.add(entry("two"), deviceId: "d1", userId: "u1")
        let sent = Mutex<[String]>([])
        let result = await queue.deliver(userId: "u1") { item in sent.withLock { $0.append(item.entry.text) } }
        #expect(sent.withLock { $0 } == ["one", "two"])
        #expect(result.delivered.count == 2)
        #expect(result.stop == .done)
        #expect(await queue.items.isEmpty)
        #expect(await JournalQueue(url: url).items.isEmpty)
    }

    @Test func networkProblemStopsAndKeepsTheEntries() async throws {
        let queue = JournalQueue(url: url)
        try await queue.add(entry("one"), deviceId: "d1", userId: "u1")
        try await queue.add(entry("two"), deviceId: "d1", userId: "u1")
        let calls = Mutex(0)
        let result = await queue.deliver(userId: "u1") { _ in
            calls.withLock { $0 += 1 }
            throw URLError(.notConnectedToInternet)
        }
        #expect(calls.withLock { $0 } == 1)
        guard case .later = result.stop else { Issue.record("expected later"); return }
        #expect(await queue.items.map(\.state) == [.waiting, .waiting])
    }

    @Test func serverErrorStopsAndKeepsTheEntries() async throws {
        let queue = JournalQueue(url: url)
        try await queue.add(entry("one"), deviceId: "d1", userId: "u1")
        let result = await queue.deliver(userId: "u1") { _ in throw OptiCloudError.http(status: 503) }
        #expect(result.stop == .later(message: "HTTP 503"))
        #expect(await queue.items.first?.state == .waiting)
    }

    @Test func expiredSessionAsksForSignIn() async throws {
        let queue = JournalQueue(url: url)
        try await queue.add(entry("one"), deviceId: "d1", userId: "u1")
        let refused = OptiCloudError.api(status: 401, body: APIErrorBody(message: "Token has expired", errorCode: 11))
        #expect(await queue.deliver(userId: "u1") { _ in throw refused }.stop == .signInNeeded)
        #expect(await queue.deliver(userId: nil) { _ in }.stop == .signInNeeded)
        #expect(await queue.items.count == 1)
    }

    @Test func refusedEntryIsSetAsideAndTheNextIsDelivered() async throws {
        let queue = JournalQueue(url: url)
        try await queue.add(entry("one"), deviceId: "gone", userId: "u1")
        try await queue.add(entry("two"), deviceId: "d1", userId: "u1")
        let result = await queue.deliver(userId: "u1") { item in
            if item.deviceId == "gone" {
                throw OptiCloudError.api(status: 404, body: APIErrorBody(message: "Device not found", errorCode: 32))
            }
        }
        #expect(result.delivered.map(\.entry.text) == ["two"])
        #expect(result.setAside.map(\.entry.text) == ["one"])
        #expect(await queue.items.map(\.state) == [.setAside(message: "Device not found")])

        // Set aside, it is not sent again until the user asks for it.
        let sent = Mutex(0)
        _ = await queue.deliver(userId: "u1") { _ in sent.withLock { $0 += 1 } }
        #expect(sent.withLock { $0 } == 0)
        let id = try #require(await queue.items.first?.id)
        try await queue.retry(id: id)
        _ = await queue.deliver(userId: "u1") { _ in sent.withLock { $0 += 1 } }
        #expect(sent.withLock { $0 } == 1)
        #expect(await queue.items.isEmpty)
    }

    @Test func entriesOfAnotherUserWait() async throws {
        let queue = JournalQueue(url: url)
        try await queue.add(entry("first user"), deviceId: "d1", userId: "u1")
        try await queue.add(entry("second user"), deviceId: "d1", userId: "u2")
        let sent = Mutex<[String]>([])
        _ = await queue.deliver(userId: "u2") { item in sent.withLock { $0.append(item.entry.text) } }
        #expect(sent.withLock { $0 } == ["second user"])
        #expect(await queue.items.map(\.userId) == ["u1"])
    }

    @Test func fullQueueRefusesNewEntries() async throws {
        let queue = JournalQueue(url: url, maxEntries: 1)
        try await queue.add(entry("one"), deviceId: "d1", userId: "u1")
        await #expect(throws: JournalQueue.QueueError.full) {
            try await queue.add(entry("two"), deviceId: "d1", userId: "u1")
        }
    }

    @Test func unreadableFileIsKeptAside() async throws {
        try Data("not json".utf8).write(to: url)
        let queue = JournalQueue(url: url)
        #expect(await queue.items.isEmpty)
        #expect(FileManager.default.fileExists(atPath: url.appendingPathExtension("unreadable").path))
    }

    @Test func noteIsCreatedThroughTheSession() async throws {
        let token = jwt(["tenantId": "t1", "projectId": "p1", "userId": "u1", "authorityDataId": "a1", "exp": 1_760_003_600])
        let transport = MockTransport([.init(status: 200, body: #"{"id":{"entityType":"NOTE","id":"n1"}}"#)])
        let client = OptiCloudClient(
            address: ServerAddress(parsing: "https://cloud.example.com")!,
            tokens: TokenPair(token: token, refreshToken: "r1"), transport: transport,
            now: { Date(timeIntervalSince1970: 1_760_000_000) }
        )
        let claims = try #require(await client.claims?.noteClaims)
        try await client.createNote(NoteRequest(entry: entry("Brake test"), claims: claims, deviceId: "d1"))
        #expect(transport.requests.first?.httpMethod == "POST")
        #expect(transport.requests.first?.url?.path() == "/api/notes")
        guard case .object(let sent) = try body(of: transport.requests[0]) else { Issue.record("no body"); return }
        #expect(sent["name"] == .string("Brake test"))
    }
}

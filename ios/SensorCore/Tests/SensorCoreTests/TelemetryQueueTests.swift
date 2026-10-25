import Foundation
import Testing
@testable import SensorCore

@Suite struct TelemetryQueueTests {
    private func makeQueue(maxBytes: Int = TelemetryQueue.defaultMaxBytes, maxPayloadBytes: Int = Telemetry.maxPayloadBytes) throws -> (TelemetryQueue, URL) {
        let url = FileManager.default.temporaryDirectory.appending(path: "queue-\(UUID().uuidString).sqlite")
        return (try TelemetryQueue(url: url, maxBytes: maxBytes, maxPayloadBytes: maxPayloadBytes), url)
    }

    private func sample(_ ts: Int64) -> Sample {
        Sample(ts: ts, values: ["batteryLevel": 0.5])
    }

    @Test func deliversInOrderAndRemovesAcknowledgedMessages() async throws {
        let (queue, _) = try makeQueue()
        try await queue.append(sample(2))
        try await queue.append(sample(1))
        let message = try #require(try await queue.nextMessage())
        #expect(message.samples.map(\.ts) == [2, 1])
        #expect(String(decoding: message.payload, as: UTF8.self)
            == #"[{"ts":1,"values":{"batteryLevel":0.5}},{"ts":2,"values":{"batteryLevel":0.5}}]"#)

        try await queue.append(sample(3))
        try await queue.remove(message)
        let next = try #require(try await queue.nextMessage())
        #expect(next.samples.map(\.ts) == [3])
        try await queue.remove(next)
        #expect(try await queue.nextMessage() == nil)
        #expect(try await queue.status().count == 0)
    }

    @Test func splitsMessagesAtThePayloadLimit() async throws {
        let size = try Telemetry.encodedSize(sample(1))
        // Room for two samples: brackets, two samples, one comma.
        let (queue, _) = try makeQueue(maxPayloadBytes: 2 + 2 * size + 1)
        for ts in 1...5 { try await queue.append(sample(Int64(ts))) }
        var batches: [[Int64]] = []
        while let message = try await queue.nextMessage() {
            #expect(message.payload.count <= 2 + 2 * size + 1)
            batches.append(message.samples.map(\.ts))
            try await queue.remove(message)
        }
        #expect(batches == [[1, 2], [3, 4], [5]])
    }

    @Test func survivesReopening() async throws {
        let (queue, url) = try makeQueue()
        try await queue.append(sample(7))
        let reopened = try TelemetryQueue(url: url)
        #expect(try await reopened.status().count == 1)
        #expect(try await reopened.status().oldestTs == 7)
    }

    @Test func discardsOldestSamplesWhenFull() async throws {
        let size = try Telemetry.encodedSize(sample(1))
        let (queue, _) = try makeQueue(maxBytes: 3 * size)
        for ts in 1...5 { try await queue.append(sample(Int64(ts))) }
        let status = try await queue.status()
        #expect(status.count == 3)
        #expect(status.bytes == 3 * size)
        #expect(status.oldestTs == 3)
        #expect(status.discarded == 2)
        #expect(status.discardedFrom == 1)
        #expect(status.discardedTo == 2)

        try await queue.resetDiscarded()
        let reset = try await queue.status()
        #expect(reset.discarded == 0)
        #expect(reset.discardedFrom == nil)
    }

    @Test func discardingAMessageCountsItsSamples() async throws {
        let (queue, _) = try makeQueue()
        for ts in 10...12 { try await queue.append(sample(Int64(ts))) }
        let message = try #require(try await queue.nextMessage())
        try await queue.append(sample(13))
        try await queue.discard(message)
        let status = try await queue.status()
        #expect(status.count == 1)
        #expect(status.discarded == 3)
        #expect(status.discardedFrom == 10)
        #expect(status.discardedTo == 12)
    }

    @Test func signalsAppendedSamples() async throws {
        let (queue, _) = try makeQueue()
        let additions = await queue.additions()
        try await queue.append(sample(1))
        var iterator = additions.makeAsyncIterator()
        #expect(await iterator.next() != nil)
    }
}

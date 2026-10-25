import Foundation
import SensorCore
import Testing

/// Runs every case of the shared test vectors in `docs/spec/vectors/`.
/// A failing vector is a defect in the app, not in the vector.
struct VectorTests {
    // MARK: telemetry.json

    struct TelemetryCase: Decodable, CustomTestStringConvertible {
        let name: String
        let samples: [Sample]
        let topic: String
        let payload: JSONValue
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("telemetry", as: TelemetryCase.self))
    func telemetry(_ vector: TelemetryCase) throws {
        #expect(Telemetry.topic == vector.topic)
        #expect(try jsonValue(Telemetry.payload(vector.samples)) == vector.payload)
    }

    // MARK: rounding.json

    struct RoundingCase: Decodable, CustomTestStringConvertible {
        let name: String
        let key: String
        let resolution: Double
        let value: Double
        let rounded: Double
        let written: String?
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("rounding", as: RoundingCase.self))
    func rounding(_ vector: RoundingCase) throws {
        let resolution = try #require(Resolution(step: vector.resolution))
        #expect(Catalog.resolution(ofValueKey: vector.key) == resolution, "catalog resolution of \(vector.key)")
        let rounded = resolution.round(vector.value)
        #expect(rounded == vector.rounded)
        // Compared as a JSON number, as it is sent.
        #expect(try jsonValue(TelemetryValue.number(rounded)) == .number(vector.rounded))
        if let written = vector.written {
            #expect(try String(decoding: JSONEncoder().encode(TelemetryValue.number(rounded)), as: UTF8.self) == written)
        }
    }

    @Test func negativeZeroIsSentAsZero() throws {
        let text = try String(decoding: JSONEncoder().encode(TelemetryValue.number(-0.0)), as: UTF8.self)
        #expect(text == "0")
    }

    // MARK: aggregation.json

    struct AggregationCase: Decodable, CustomTestStringConvertible {
        let name: String
        let key: String
        let measurements: [Double]?
        let measurements3: [[Double]]?
        let values: [String: TelemetryValue]
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("aggregation", as: AggregationCase.self))
    func aggregation(_ vector: AggregationCase) throws {
        let measurements = vector.measurements
            ?? (vector.measurements3 ?? []).map { Aggregate.magnitude(x: $0[0], y: $0[1], z: $0[2]) }
        let aggregate = Aggregate(measurements)
        let values = aggregate.values(key: vector.key, resolution: Catalog.resolution(ofValueKey: vector.key))
        #expect(values == vector.values)
    }

    // MARK: selection.json

    struct SelectionCase: Decodable, CustomTestStringConvertible {
        let name: String
        let offered: [String]
        let selection: String
        let valid: Bool
        let items: [String]?
        let reported: [String]?
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("selection", as: SelectionCase.self))
    func selection(_ vector: SelectionCase) throws {
        let selection = Selection(parsing: vector.selection)
        #expect((selection != nil) == vector.valid)
        guard let selection else { return }
        let offered = Set(vector.offered)
        #expect(selection.items(offered: offered).map(\.key) == vector.items)
        #expect(Set(selection.reportedEntries(offered: offered)) == Set(vector.reported ?? []))
    }

    // MARK: on-change.json

    struct OnChangeCase: Decodable, CustomTestStringConvertible {
        struct Tick: Decodable {
            let ts: Int64
            let values: [String: TelemetryValue]
            let selectionChanged: Bool?
        }

        let name: String
        let mode: SendMode
        let ticks: [Tick]
        let sent: [Sample]
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("on-change", as: OnChangeCase.self))
    func onChange(_ vector: OnChangeCase) throws {
        var filter = SendFilter(mode: vector.mode)
        var sent: [Sample] = []
        for tick in vector.ticks {
            if tick.selectionChanged == true { filter.selectionDidChange() }
            if let sample = filter.sample(at: tick.ts, measured: tick.values) { sent.append(sample) }
        }
        #expect(sent == vector.sent)
    }

    // MARK: queue-batching.json

    struct QueueBatchingCase: Decodable, CustomTestStringConvertible {
        let name: String
        let maxPayloadBytes: Int
        let queue: [Sample]
        let messages: [JSONValue]
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("queue-batching", as: QueueBatchingCase.self))
    func queueBatching(_ vector: QueueBatchingCase) throws {
        let messages = try Telemetry.messages(from: vector.queue, maxPayloadBytes: vector.maxPayloadBytes)
        let payloads = try messages.map { try Telemetry.payload($0) }
        #expect(try payloads.map(jsonValue) == vector.messages)
        // Only a single sample that is too large on its own may exceed the limit.
        for (message, payload) in zip(messages, payloads) where message.count > 1 {
            #expect(payload.count <= vector.maxPayloadBytes)
        }
    }

    // MARK: journal-note.json

    struct JournalNoteCase: Decodable, CustomTestStringConvertible {
        let name: String
        let entry: JournalEntry
        let claims: NoteClaims
        let deviceId: String
        let body: JSONValue
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("journal-note", as: JournalNoteCase.self))
    func journalNote(_ vector: JournalNoteCase) throws {
        let request = NoteRequest(entry: vector.entry, claims: vector.claims, deviceId: vector.deviceId)
        #expect(try jsonValue(request) == vector.body)
    }
}

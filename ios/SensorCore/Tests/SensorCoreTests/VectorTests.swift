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

    // MARK: orientation.json

    struct OrientationCase: Decodable, CustomTestStringConvertible {
        let name: String
        let gravity: [Double]
        let magneticField: [Double]?
        let values: [String: Double]
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("orientation", as: OrientationCase.self))
    func orientation(_ vector: OrientationCase) throws {
        let g = vector.gravity
        let m = vector.magneticField
        let angles = Orientation.angles(gravity: (g[0], g[1], g[2]), magneticField: m.map { ($0[0], $0[1], $0[2]) })
        let rounded = angles.mapValues { value -> Double? in
            if case .number(let number) = value { return number }
            return nil
        }
        let expected = vector.values.mapValues { Optional($0) }
        #expect(rounded.mapValues { $0.map { Catalog.resolution(ofValueKey: "yaw")!.round($0) } } == expected)
    }

    // MARK: sound-level.json

    struct SoundLevelCase: Decodable, CustomTestStringConvertible {
        let name: String
        let samples: [Float]
        let level: Double?
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("sound-level", as: SoundLevelCase.self))
    func soundLevel(_ vector: SoundLevelCase) throws {
        var level = SoundLevel()
        level.add(vector.samples)
        #expect(level.level.map { Catalog.resolution(ofValueKey: "soundLevel")!.round($0) } == vector.level)
    }

    // MARK: test-signal.json

    struct TestSignalCase: Decodable, CustomTestStringConvertible {
        let name: String
        let ts: Int64
        let testSine: Double
        let written: String?
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("test-signal", as: TestSignalCase.self))
    func testSignal(_ vector: TestSignalCase) throws {
        let value = SendFilter.round(.number(TestSignal.sine(at: vector.ts)), key: "testSine")
        #expect(try jsonValue(value) == .number(vector.testSine))
        if let written = vector.written {
            #expect(try String(decoding: JSONEncoder().encode(value), as: UTF8.self) == written)
        }
    }

    // MARK: favorite-url.json

    struct FavoriteURLCase: Decodable, CustomTestStringConvertible {
        let name: String
        let address: String
        let path: String
        let url: String?
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("favorite-url", as: FavoriteURLCase.self))
    func favoriteURL(_ vector: FavoriteURLCase) throws {
        let address = try #require(ServerAddress(parsing: vector.address))
        #expect(address.pageURL(path: vector.path)?.absoluteString == vector.url)
    }

    // MARK: mqtt-packet-size.json

    struct PacketSizeCase: Decodable, CustomTestStringConvertible {
        let name: String
        let packet: String
        let topic: String?
        let payloadBytes: Int?
        let qos: Int?
        let clientId: String?
        let userName: String?
        let topicFilters: [String]?
        let count: Int?
        let bytes: Int
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("mqtt-packet-size", as: PacketSizeCase.self))
    func mqttPacketSize(_ vector: PacketSizeCase) throws {
        let size: Int
        switch vector.packet {
        case "publish": size = MQTTPacketSize.publish(topic: vector.topic!, payloadBytes: vector.payloadBytes!, qos: vector.qos!)
        case "connect": size = MQTTPacketSize.connect(clientId: vector.clientId!, userName: vector.userName!)
        case "subscribe": size = MQTTPacketSize.subscribe(topicFilters: vector.topicFilters!)
        case "suback": size = MQTTPacketSize.suback(count: vector.count!)
        case "connack": size = MQTTPacketSize.connack
        case "puback": size = MQTTPacketSize.puback
        case "pingreq": size = MQTTPacketSize.pingreq
        case "pingresp": size = MQTTPacketSize.pingresp
        default: Issue.record("unknown packet \(vector.packet)"); return
        }
        #expect(size == vector.bytes)
    }

    // MARK: data-volume.json

    struct DataVolumeCase: Decodable, CustomTestStringConvertible {
        struct Transfer: Decodable {
            let day: String
            let network: DataNetwork
            let direction: String
            let bytes: Int
        }
        let name: String
        let now: String
        let transfers: [Transfer]
        let today: DataVolume.Counters
        let week: DataVolume.Counters
        let month: DataVolume.Counters
        let telemetry: [String: Double]
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("data-volume", as: DataVolumeCase.self))
    func dataVolume(_ vector: DataVolumeCase) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
        func date(_ day: String) -> Date {
            let parts = day.split(separator: "-").map { Int($0)! }
            // Noon, so that the day is clear in any time zone of the calendar.
            return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))!
        }
        var volume = DataVolume()
        for transfer in vector.transfers {
            volume.count(transfer.bytes, transfer.direction == "sent" ? .sent : .received, transfer.network,
                         at: date(transfer.day), calendar: calendar)
        }
        let now = date(vector.now)
        #expect(volume.total(.today, at: now, calendar: calendar) == vector.today)
        #expect(volume.total(.week, at: now, calendar: calendar) == vector.week)
        #expect(volume.total(.month, at: now, calendar: calendar) == vector.month)
        #expect(volume.telemetry(at: now, calendar: calendar) == vector.telemetry.mapValues { .number($0) })
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

    // MARK: journal-title.json

    struct JournalTitleCase: Decodable, CustomTestStringConvertible {
        let name: String
        let title: String
        let text: String
        let expected: String
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("journal-title", as: JournalTitleCase.self))
    func journalTitle(_ vector: JournalTitleCase) {
        let entry = JournalEntry(title: vector.title, text: vector.text, savedAt: 0, utcOffsetMinutes: 0)
        #expect(entry.noteName == vector.expected)
    }

    // MARK: start-screen.json

    struct StartScreenCase: Decodable, CustomTestStringConvertible {
        let name: String
        let lastSeen: String?
        let version: String
        let hasDevice: Bool
        let hasHighlights: Bool
        let screen: StartScreen?
        var testDescription: String { name }
    }

    @Test(arguments: try TestVectors.cases("start-screen", as: StartScreenCase.self))
    func startScreen(_ vector: StartScreenCase) {
        let screen = StartScreen.at(lastSeen: vector.lastSeen, version: vector.version, hasDevice: vector.hasDevice, hasHighlights: vector.hasHighlights)
        #expect(screen == vector.screen)
    }
}

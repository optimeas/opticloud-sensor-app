import Foundation
import SQLite3

/// The persistent offline queue of telemetry samples (see `docs/spec/offline-queue.md`).
///
/// Samples are kept in an SQLite database in the order they were appended. Every sample goes through the queue,
/// also while the app is connected.
public actor TelemetryQueue {
    /// The largest size of the queue, counted as the size of the samples in JSON.
    public static let defaultMaxBytes = 50 * 1024 * 1024

    /// What the test area shows about the queue.
    public struct Status: Hashable, Sendable {
        public var count: Int
        public var bytes: Int
        /// The time stamp of the oldest sample, in milliseconds since 1970.
        public var oldestTs: Int64?
        /// Samples discarded since the count was last reset, and the time range they covered.
        public var discarded: Int
        public var discardedFrom: Int64?
        public var discardedTo: Int64?
    }

    /// The samples of one telemetry message, taken from the front of the queue.
    public struct Message: Sendable {
        /// The rows of the first and the last sample in the message.
        public let firstRow: Int64
        public let lastRow: Int64
        public let samples: [Sample]
        public let payload: Data
    }

    // Used only on the actor and in deinit.
    nonisolated(unsafe) private let db: OpaquePointer
    private let maxBytes: Int
    private let maxPayloadBytes: Int
    private var listener: AsyncStream<Void>.Continuation?

    /// Opens or creates the queue at `url`.
    public init(url: URL, maxBytes: Int = defaultMaxBytes, maxPayloadBytes: Int = Telemetry.maxPayloadBytes) throws {
        var handle: OpaquePointer?
        guard sqlite3_open_v2(url.path, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK,
              let handle
        else {
            sqlite3_close(handle)
            throw QueueError.cannotOpen
        }
        db = handle
        self.maxBytes = maxBytes
        self.maxPayloadBytes = maxPayloadBytes
        try Self.execute(handle, """
            PRAGMA journal_mode = WAL;
            CREATE TABLE IF NOT EXISTS sample (row INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER NOT NULL, size INTEGER NOT NULL, json BLOB NOT NULL);
            CREATE TABLE IF NOT EXISTS discarded (id INTEGER PRIMARY KEY CHECK (id = 1), count INTEGER NOT NULL, fromTs INTEGER, toTs INTEGER);
            INSERT OR IGNORE INTO discarded (id, count) VALUES (1, 0);
            """)
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: Storing

    /// Appends a sample at the end. When the queue is full, the oldest samples are discarded until it fits.
    public func append(_ sample: Sample) throws {
        let json = try Telemetry.encoder.encode(sample)
        var total = try status().bytes
        while total + json.count > maxBytes, let oldest = try oldestRow() {
            try discard(rows: oldest.row ... oldest.row)
            total -= oldest.size
        }
        try run("INSERT INTO sample (ts, size, json) VALUES (?, ?, ?)", .int(sample.ts), .int(Int64(json.count)), .blob(json))
        listener?.yield()
    }

    /// A signal for each appended sample. Only the latest caller receives it.
    public func additions() -> AsyncStream<Void> {
        listener?.finish()
        let (stream, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        listener = continuation
        return stream
    }

    // MARK: Delivering

    /// The next message from the front of the queue, or nil if the queue is empty.
    /// The message takes samples until the next one would make its payload larger than the limit.
    public func nextMessage() throws -> Message? {
        var samples: [Sample] = []
        var firstRow: Int64 = 0
        var lastRow: Int64 = 0
        var size = 2 // the brackets of the array
        try query("SELECT row, size, json FROM sample ORDER BY row LIMIT 1000") { statement in
            let sampleSize = Int(sqlite3_column_int64(statement, 1))
            let added = samples.isEmpty ? sampleSize : sampleSize + 1
            if !samples.isEmpty && size + added > maxPayloadBytes { return false }
            let bytes = sqlite3_column_blob(statement, 2)
            let json = Data(bytes: bytes!, count: Int(sqlite3_column_bytes(statement, 2)))
            samples.append(try JSONDecoder().decode(Sample.self, from: json))
            lastRow = sqlite3_column_int64(statement, 0)
            if samples.count == 1 { firstRow = lastRow }
            size += added
            return true
        }
        guard !samples.isEmpty else { return nil }
        return Message(firstRow: firstRow, lastRow: lastRow, samples: samples, payload: try Telemetry.payload(samples))
    }

    /// Removes a message after the server has acknowledged it.
    public func remove(_ message: Message) throws {
        try run("DELETE FROM sample WHERE row <= ?", .int(message.lastRow))
    }

    /// Discards a message the server cannot read, and counts its samples as discarded.
    public func discard(_ message: Message) throws {
        try discard(rows: message.firstRow ... message.lastRow)
    }

    /// Discards all samples, for example when another device is picked. They are not counted as discarded.
    public func removeAll() throws {
        try run("DELETE FROM sample")
    }

    // MARK: Status

    public func status() throws -> Status {
        var status = Status(count: 0, bytes: 0, discarded: 0)
        try query("SELECT COUNT(*), COALESCE(SUM(size), 0), MIN(ts) FROM sample") { statement in
            status.count = Int(sqlite3_column_int64(statement, 0))
            status.bytes = Int(sqlite3_column_int64(statement, 1))
            status.oldestTs = Self.optionalInt(statement, 2)
            return false
        }
        try query("SELECT count, fromTs, toTs FROM discarded WHERE id = 1") { statement in
            status.discarded = Int(sqlite3_column_int64(statement, 0))
            status.discardedFrom = Self.optionalInt(statement, 1)
            status.discardedTo = Self.optionalInt(statement, 2)
            return false
        }
        return status
    }

    /// Resets the count of discarded samples.
    public func resetDiscarded() throws {
        try run("UPDATE discarded SET count = 0, fromTs = NULL, toTs = NULL WHERE id = 1")
    }

    // MARK: Internals

    private func oldestRow() throws -> (row: Int64, size: Int)? {
        var result: (Int64, Int)?
        try query("SELECT row, size FROM sample ORDER BY row LIMIT 1") { statement in
            result = (sqlite3_column_int64(statement, 0), Int(sqlite3_column_int64(statement, 1)))
            return false
        }
        return result
    }

    private func discard(rows: ClosedRange<Int64>) throws {
        try run("""
            UPDATE discarded SET
                count = count + (SELECT COUNT(*) FROM sample WHERE row BETWEEN ?1 AND ?2),
                fromTs = MIN(COALESCE(fromTs, 9223372036854775807), COALESCE((SELECT MIN(ts) FROM sample WHERE row BETWEEN ?1 AND ?2), 9223372036854775807)),
                toTs = MAX(COALESCE(toTs, -1), COALESCE((SELECT MAX(ts) FROM sample WHERE row BETWEEN ?1 AND ?2), -1))
            WHERE id = 1
            """, .int(rows.lowerBound), .int(rows.upperBound))
        try run("UPDATE discarded SET fromTs = NULL, toTs = NULL WHERE id = 1 AND count = 0")
        try run("DELETE FROM sample WHERE row BETWEEN ? AND ?", .int(rows.lowerBound), .int(rows.upperBound))
    }

    private enum Parameter {
        case int(Int64)
        case blob(Data)
    }

    private func run(_ sql: String, _ parameters: Parameter...) throws {
        try query(sql, parameters) { _ in false }
    }

    /// Runs a statement and calls `row` for each result row until it returns false.
    private func query(_ sql: String, _ parameters: [Parameter] = [], row: (OpaquePointer) throws -> Bool) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw QueueError.sqlite(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        for (index, parameter) in parameters.enumerated() {
            let position = Int32(index + 1)
            switch parameter {
            case .int(let value):
                sqlite3_bind_int64(statement, position, value)
            case .blob(let data):
                _ = data.withUnsafeBytes { buffer in
                    sqlite3_bind_blob(statement, position, buffer.baseAddress, Int32(buffer.count), Self.transient)
                }
            }
        }
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                if try !row(statement) { return }
            case SQLITE_DONE:
                return
            default:
                throw QueueError.sqlite(String(cString: sqlite3_errmsg(db)))
            }
        }
    }

    private static func execute(_ db: OpaquePointer, _ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw QueueError.sqlite(String(cString: sqlite3_errmsg(db)))
        }
    }

    private static func optionalInt(_ statement: OpaquePointer, _ column: Int32) -> Int64? {
        sqlite3_column_type(statement, column) == SQLITE_NULL ? nil : sqlite3_column_int64(statement, column)
    }

    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
}

public enum QueueError: Error, Sendable {
    case cannotOpen
    case sqlite(String)
}

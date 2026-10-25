import Foundation

/// Telemetry messages (see `docs/spec/messages.md`, Telemetry, and `docs/spec/offline-queue.md`, Delivering).
public enum Telemetry {
    public static let topic = "v2/json/devices/me/telemetry"

    /// The largest payload the app sends, in bytes.
    public static let maxPayloadBytes = 32_768

    /// The payload of one message: the samples as a JSON array, ordered by rising time stamp, without white space.
    public static func payload(_ samples: [Sample]) throws -> Data {
        try encoder.encode(ordered(samples))
    }

    /// Divides the front of the queue into messages, in the order they are sent. A message takes samples until
    /// the next one would make its payload larger than `maxPayloadBytes`. A single sample that is larger on its
    /// own goes into a message of its own.
    public static func messages(from queue: [Sample], maxPayloadBytes: Int = maxPayloadBytes) throws -> [[Sample]] {
        var messages: [[Sample]] = []
        var current: [Sample] = []
        var currentSize = 2 // the brackets of the array
        for sample in queue {
            let size = try encodedSize(sample)
            let added = current.isEmpty ? size : size + 1 // a comma before every sample but the first
            if !current.isEmpty && currentSize + added > maxPayloadBytes {
                messages.append(ordered(current))
                current = []
                currentSize = 2
                currentSize += size
            } else {
                currentSize += added
            }
            current.append(sample)
        }
        if !current.isEmpty { messages.append(ordered(current)) }
        return messages
    }

    /// The length of a sample in UTF-8, written as JSON without white space.
    public static func encodedSize(_ sample: Sample) throws -> Int {
        try encoder.encode(sample).count
    }

    /// Orders samples by rising time stamp; samples with the same time stamp keep their order.
    static func ordered(_ samples: [Sample]) -> [Sample] {
        samples.enumerated()
            .sorted { ($0.element.ts, $0.offset) < ($1.element.ts, $1.offset) }
            .map(\.element)
    }

    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}

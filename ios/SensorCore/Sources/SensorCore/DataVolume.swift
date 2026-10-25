import Foundation

/// The network a transfer went over, as the system reports it at that moment. Networks other than the mobile
/// network count as Wi-Fi (see `docs/spec/connection.md`, Data volume).
public enum DataNetwork: String, Codable, Sendable {
    case mobile
    case wifi
}

public enum DataDirection: Sendable {
    case sent
    case received
}

/// The sizes of the MQTT 3.1.1 packets the app sends and receives, in bytes, without the overhead of TLS, TCP, and IP.
public enum MQTTPacketSize {
    public static let connack = 4
    public static let puback = 4
    public static let pingreq = 2
    public static let pingresp = 2

    /// CONNECT with a client identifier and a user name, without password and will.
    public static func connect(clientId: String, userName: String) -> Int {
        // Protocol name (6), level (1), flags (1), keep-alive (2).
        packet(remaining: 10 + string(clientId) + string(userName))
    }

    public static func subscribe(topicFilters: [String]) -> Int {
        // Packet identifier, then each filter with its QoS byte.
        packet(remaining: 2 + topicFilters.reduce(0) { $0 + string($1) + 1 })
    }

    public static func suback(count: Int) -> Int {
        packet(remaining: 2 + count)
    }

    public static func publish(topic: String, payloadBytes: Int, qos: Int) -> Int {
        packet(remaining: string(topic) + (qos > 0 ? 2 : 0) + payloadBytes)
    }

    /// The fixed header (one byte for the type, one to four for the remaining length) and the rest.
    static func packet(remaining: Int) -> Int {
        var lengthBytes = 1
        var rest = remaining / 128
        while rest > 0 {
            lengthBytes += 1
            rest /= 128
        }
        return 1 + lengthBytes + remaining
    }

    private static func string(_ text: String) -> Int {
        2 + text.utf8.count
    }
}

/// The size of an HTTP request or answer as the app sees it: start line, header lines, blank line, and body.
public enum HTTPMessageSize {
    public static func request(method: String, path: String, headers: [String: String], bodyBytes: Int) -> Int {
        let startLine = "\(method) \(path) HTTP/1.1\r\n"
        return startLine.utf8.count + headerBytes(headers) + 2 + bodyBytes
    }

    public static func response(status: Int, headers: [String: String], bodyBytes: Int) -> Int {
        let startLine = "HTTP/1.1 \(status)\r\n"
        return startLine.utf8.count + headerBytes(headers) + 2 + bodyBytes
    }

    private static func headerBytes(_ headers: [String: String]) -> Int {
        headers.reduce(0) { $0 + "\($1.key): \($1.value)\r\n".utf8.count }
    }
}

/// The counters of the app's own data volume, per day in the local time of the phone
/// (see `docs/spec/connection.md`, Data volume).
public struct DataVolume: Codable, Hashable, Sendable {
    /// Added to every MQTT packet and every HTTP request and answer for TLS, TCP, and IP.
    public static let overheadPerMessage = 80

    public struct Counters: Codable, Hashable, Sendable {
        public var mobileSent: Int64 = 0
        public var mobileReceived: Int64 = 0
        public var wifiSent: Int64 = 0
        public var wifiReceived: Int64 = 0

        public init() {}

        public var mobile: Int64 { mobileSent + mobileReceived }
        public var wifi: Int64 { wifiSent + wifiReceived }

        mutating func add(_ bytes: Int64, _ direction: DataDirection, _ network: DataNetwork) {
            switch (network, direction) {
            case (.mobile, .sent): mobileSent += bytes
            case (.mobile, .received): mobileReceived += bytes
            case (.wifi, .sent): wifiSent += bytes
            case (.wifi, .received): wifiReceived += bytes
            }
        }

        static func + (lhs: Counters, rhs: Counters) -> Counters {
            var sum = lhs
            sum.mobileSent += rhs.mobileSent
            sum.mobileReceived += rhs.mobileReceived
            sum.wifiSent += rhs.wifiSent
            sum.wifiReceived += rhs.wifiReceived
            return sum
        }
    }

    public enum Period: Sendable {
        case today
        /// From Monday.
        case week
        case month
    }

    /// The counters by day, keyed `yyyy-MM-dd`.
    public private(set) var days: [String: Counters] = [:]

    public init() {}

    /// Counts one message of `bytes`, adding the overhead.
    public mutating func count(_ bytes: Int, _ direction: DataDirection, _ network: DataNetwork, at date: Date, calendar: Calendar) {
        days[Self.key(date, calendar), default: Counters()].add(Int64(bytes + Self.overheadPerMessage), direction, network)
    }

    public func total(_ period: Period, at date: Date, calendar: Calendar) -> Counters {
        let today = calendar.startOfDay(for: date)
        let start: Date
        switch period {
        case .today:
            start = today
        case .week:
            // Monday is weekday 2 in the Gregorian numbering.
            let weekday = calendar.component(.weekday, from: today)
            start = calendar.date(byAdding: .day, value: -((weekday + 5) % 7), to: today)!
        case .month:
            start = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        }
        var sum = Counters()
        var day = start
        while day <= today {
            if let counters = days[Self.key(day, calendar)] { sum = sum + counters }
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        return sum
    }

    /// The values of the item `dataVolume` (see `docs/spec/sensors.md`, `device`).
    public func telemetry(at date: Date, calendar: Calendar) -> [String: TelemetryValue] {
        let today = total(.today, at: date, calendar: calendar)
        let month = total(.month, at: date, calendar: calendar)
        return [
            "dataMobileToday": .number(Double(today.mobile)),
            "dataWifiToday": .number(Double(today.wifi)),
            "dataMobileMonth": .number(Double(month.mobile)),
            "dataWifiMonth": .number(Double(month.wifi)),
        ]
    }

    /// Removes the days before the previous month; the counters are kept until the end of the following month.
    public mutating func removeOld(at date: Date, calendar: Calendar) {
        let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: thisMonth)!
        let oldest = Self.key(previousMonth, calendar)
        days = days.filter { $0.key >= oldest }
    }

    static func key(_ date: Date, _ calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
}

import Foundation

/// A journal entry as the user saved it (see `docs/spec/journal.md`, Entry).
public struct JournalEntry: Hashable, Codable, Sendable {
    public enum Status: String, Codable, Sendable, CaseIterable {
        case created = "CREATED"
        case archived = "ARCHIVED"
    }

    public enum Priority: String, Codable, Sendable, CaseIterable {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
    }

    public var title: String
    public var text: String
    public var status: Status
    public var priority: Priority
    /// The moment of saving in milliseconds since 1970.
    public var savedAt: Int64
    /// The offset of the phone's time zone from UTC at the moment of saving.
    public var utcOffsetMinutes: Int
    public var latitude: Double?
    public var longitude: Double?

    public init(
        title: String, text: String, status: Status = .created, priority: Priority = .medium,
        savedAt: Int64, utcOffsetMinutes: Int, latitude: Double? = nil, longitude: Double? = nil
    ) {
        self.title = title
        self.text = text
        self.status = status
        self.priority = priority
        self.savedAt = savedAt
        self.utcOffsetMinutes = utcOffsetMinutes
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// The identifiers a note needs from the claims of the user's access token.
public struct NoteClaims: Hashable, Codable, Sendable {
    public var tenantId: String
    public var projectId: String
    public var authorityDataId: String

    public init(tenantId: String, projectId: String, authorityDataId: String) {
        self.tenantId = tenantId
        self.projectId = projectId
        self.authorityDataId = authorityDataId
    }
}

/// The body of `POST /api/notes` that creates a note from a journal entry (see `docs/spec/journal.md`, Note).
public struct NoteRequest: Hashable, Encodable, Sendable {
    public struct EntityId: Hashable, Encodable, Sendable {
        public let entityType: String
        public let id: String
    }

    public struct AdditionalInfo: Hashable, Encodable, Sendable {
        public let source: String
        public let savedAt: Int64
        public let latitude: Double?
        public let longitude: Double?
    }

    public static let source = "optiCLOUD Sensor App"

    public let entityId: EntityId
    public let tenantId: EntityId
    public let projectId: EntityId
    public let authorityDataId: EntityId
    public let name: String
    public let text: String
    public let status: JournalEntry.Status
    public let priority: JournalEntry.Priority
    public let additionalInfo: AdditionalInfo

    public init(entry: JournalEntry, claims: NoteClaims, deviceId: String) {
        entityId = EntityId(entityType: "DEVICE", id: deviceId)
        tenantId = EntityId(entityType: "TENANT", id: claims.tenantId)
        projectId = EntityId(entityType: "PROJECT", id: claims.projectId)
        authorityDataId = EntityId(entityType: "AUTHORITY_DATA", id: claims.authorityDataId)
        name = entry.title
        text = entry.text + "\n\n" + Self.timeStamp(savedAt: entry.savedAt, utcOffsetMinutes: entry.utcOffsetMinutes)
        status = entry.status
        priority = entry.priority
        let hasPosition = entry.latitude != nil && entry.longitude != nil
        additionalInfo = AdditionalInfo(
            source: Self.source,
            savedAt: entry.savedAt,
            latitude: hasPosition ? entry.latitude : nil,
            longitude: hasPosition ? entry.longitude : nil
        )
    }

    /// The local time of saving in the form `YYYY-MM-DD HH:MM ±HH:MM`.
    public static func timeStamp(savedAt: Int64, utcOffsetMinutes: Int) -> String {
        let localSeconds = Int64((Double(savedAt) / 1000).rounded(.down)) + Int64(utcOffsetMinutes) * 60
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = Date(timeIntervalSince1970: TimeInterval(localSeconds))
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let sign = utcOffsetMinutes < 0 ? "-" : "+"
        let offset = abs(utcOffsetMinutes)
        return String(
            format: "%04d-%02d-%02d %02d:%02d %@%02d:%02d",
            parts.year!, parts.month!, parts.day!, parts.hour!, parts.minute!, sign, offset / 60, offset % 60
        )
    }
}

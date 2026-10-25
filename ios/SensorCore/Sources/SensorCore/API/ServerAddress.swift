import Foundation

/// The address of the optiCLOUD web application (see `docs/spec/connection.md`, Endpoint).
public struct ServerAddress: Hashable, Codable, Sendable {
    /// The official optiCLOUD server of optiMEAS, the default address.
    public static let official = ServerAddress(parsing: "https://dashboard.opticloud.io")!

    /// The MQTT port by convention of optiCLOUD installations.
    public static let mqttPort = 8883

    public let url: URL

    /// Accepts an address that starts with `https://` and has a host name. A path and a trailing slash are dropped.
    public init?(parsing text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix("https://"),
              var components = URLComponents(string: trimmed),
              let host = components.host, !host.isEmpty
        else { return nil }
        components.scheme = "https"
        components.path = ""
        components.query = nil
        components.fragment = nil
        components.user = nil
        components.password = nil
        guard let url = components.url else { return nil }
        self.url = url
    }

    public var host: String { url.host() ?? "" }

    /// The address as the user sees it.
    public var text: String { url.absoluteString }

    /// The URL of a path of the REST interface, such as `/api/auth/login`.
    public func url(path: String, query: [URLQueryItem] = []) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.path = path
        components.queryItems = query.isEmpty ? nil : query
        return components.url!
    }
}

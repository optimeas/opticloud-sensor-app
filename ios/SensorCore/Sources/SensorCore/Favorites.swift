import Foundation

/// A page of the optiCLOUD web application in the tab Favorites (see `docs/spec/favorites.md`).
public struct Favorite: Hashable, Sendable, Codable, Identifiable {
    /// What the page shows. The apps pick a symbol by it.
    public enum Kind: String, Hashable, Sendable, Codable {
        case home
        case dashboard
        case dashboardList
        case device
        case deviceList
        /// Another page of the web application.
        case page
        /// A page outside the web application.
        case external
    }

    public let title: String
    public let path: String

    public init(title: String, path: String) {
        self.title = title
        self.path = path
    }

    public var id: String { path }

    public var kind: Kind {
        guard path.hasPrefix("/") else { return .external }
        let parts = path.split(separator: "?", maxSplits: 1)[0].split(separator: "/")
        switch (parts.first, parts.count) {
        case ("home", 1): return .home
        case ("dashboards", 1): return .dashboardList
        case ("dashboards", _): return .dashboard
        case ("devices", 1): return .deviceList
        case ("devices", _): return .device
        default: return .page
        }
    }

    /// The identifier of the dashboard, for a favorite of kind `dashboard`.
    public var dashboardId: String? {
        guard kind == .dashboard else { return nil }
        return path.split(separator: "?", maxSplits: 1)[0].split(separator: "/").dropFirst().first.map(String.init)
    }

    public static let home = Favorite(title: "", path: "/home")

    public static func dashboard(id: String, title: String) -> Favorite {
        Favorite(title: title, path: "/dashboards/\(id)")
    }

    public static func device(id: String, title: String) -> Favorite {
        Favorite(title: title, path: "/devices/\(id)")
    }
}

extension ServerAddress {
    /// The address the app opens for the path of a favorite; nil if the favorite is left out
    /// (see `docs/spec/favorites.md`, Address of a page).
    public func pageURL(path: String) -> URL? {
        if path.hasPrefix("/") {
            return URL(string: text + path)
        }
        let lower = path.lowercased()
        guard lower.hasPrefix("https://") || lower.hasPrefix("http://") else { return nil }
        return URL(string: path)
    }
}

/// A dashboard in the list of the project (see `docs/spec/favorites.md`, Favorites on this phone).
public struct DashboardInfo: Hashable, Sendable, Decodable, Identifiable {
    public let dashboardId: EntityId
    public let title: String

    public var id: String { dashboardId.id }

    private enum CodingKeys: String, CodingKey {
        case dashboardId = "id", title
    }
}

/// The favorites of the user in the web application, from the answer of `GET /api/auth/user`.
/// A favorite without a title or a path is left out.
enum WebFavorites {
    static func favorites(inUser user: JSONValue) -> [Favorite] {
        guard case .object(let user) = user,
              case .object(let info)? = user["additionalInfo"],
              case .array(let pages)? = info["favoritePages"]
        else { return [] }
        return pages.compactMap { page in
            guard case .object(let page) = page,
                  case .string(let title)? = page["title"], !title.isEmpty,
                  case .string(let path)? = page["path"], !path.isEmpty
            else { return nil }
            return Favorite(title: title, path: path)
        }
    }
}

/// How the web application of optiCLOUD keeps its session in the browser, so that a browser view in the app can
/// start signed in (see `docs/spec/favorites.md`, Opening a page). This is not an interface optiCLOUD guarantees.
public enum WebSessionStorage {
    /// The entries of the local storage of the web application for a session: both tokens and the moments, in
    /// milliseconds since 1970, at which they expire.
    public static func entries(for session: TokenPair) -> [String: String] {
        var entries = ["jwt_token": session.token, "refresh_token": session.refreshToken]
        for (key, token) in [("jwt_token", session.token), ("refresh_token", session.refreshToken)] {
            if let expiresAt = (try? AccessTokenClaims(jwt: token))?.exp {
                entries["\(key)_expiration"] = String(expiresAt * 1000)
            }
        }
        return entries
    }
}

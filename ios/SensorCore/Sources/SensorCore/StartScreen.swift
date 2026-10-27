/// The screen the app shows at start (see `docs/spec/whats-new.md`, When a screen appears).
public enum StartScreen: String, Sendable, Codable {
    case welcome
    case whatsNew

    /// The screen for this start, or nil for none.
    /// - Parameters:
    ///   - lastSeen: The version whose screen was last shown, nil if none was kept yet.
    ///   - version: The version of the app, without the build number.
    ///   - hasDevice: A device is chosen.
    ///   - hasHighlights: The versions to show (see `versions(lastSeen:version:withHighlights:)`) have highlights.
    public static func at(lastSeen: String?, version: String, hasDevice: Bool, hasHighlights: Bool) -> StartScreen? {
        if lastSeen == version { return nil }
        if lastSeen == nil && !hasDevice { return .welcome }
        return hasHighlights ? .whatsNew : nil
    }

    /// The versions whose highlights the screen "What's New" shows, newest first (see `docs/spec/whats-new.md`,
    /// What the screen shows): those after the last seen version up to the version of the app, all up to it when none
    /// was kept, and only the version of the app when an older one was installed after a newer one.
    /// - Parameter withHighlights: The versions that have highlights.
    public static func versions(lastSeen: String?, version: String, withHighlights: [String]) -> [String] {
        let current = AppVersion(version)
        let shown = withHighlights.filter { candidate in
            let v = AppVersion(candidate)
            guard let lastSeen else { return v <= current }
            let seen = AppVersion(lastSeen)
            return seen <= current ? seen < v && v <= current : v == current
        }
        return shown.sorted { AppVersion($0) > AppVersion($1) }
    }
}

/// A version number such as 0.9.0, compared part by part; a missing part counts as 0.
struct AppVersion: Comparable {
    let parts: [Int]

    init(_ string: String) {
        parts = string.split(separator: ".").map { Int($0) ?? 0 }
    }

    static func == (a: AppVersion, b: AppVersion) -> Bool {
        !(a < b) && !(b < a)
    }

    static func < (a: AppVersion, b: AppVersion) -> Bool {
        for i in 0..<max(a.parts.count, b.parts.count) {
            let x = i < a.parts.count ? a.parts[i] : 0, y = i < b.parts.count ? b.parts[i] : 0
            if x != y { return x < y }
        }
        return false
    }
}

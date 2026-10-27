/// The screen the app shows at start (see `docs/spec/whats-new.md`, When a screen appears).
public enum StartScreen: String, Sendable, Codable {
    case welcome
    case whatsNew

    /// The screen for this start, or nil for none.
    /// - Parameters:
    ///   - lastSeen: The version whose screen was last shown, nil if none was kept yet.
    ///   - version: The version of the app, without the build number.
    ///   - hasDevice: A device is chosen.
    ///   - hasHighlights: The version of the app has highlights.
    public static func at(lastSeen: String?, version: String, hasDevice: Bool, hasHighlights: Bool) -> StartScreen? {
        if lastSeen == version { return nil }
        if lastSeen == nil && !hasDevice { return .welcome }
        return hasHighlights ? .whatsNew : nil
    }
}

import AppIntents

/// Lets the intents of the Live Activity and of Control Center switch transmission. The system runs these intents in
/// the app, which sets `handler` at launch; in the widget extension it stays nil.
@MainActor
enum TransmissionControl {
    static var handler: ((Bool) -> Void)?
}

/// The stop button of the Live Activity.
struct StopSendingIntent: LiveActivityIntent {
    static let title = LocalizedStringResource("Stop Sending", table: "Shared")
    static let description = IntentDescription(LocalizedStringResource("Stops sending to optiCLOUD.", table: "Shared"))

    @MainActor
    func perform() async throws -> some IntentResult {
        TransmissionControl.handler?(false)
        return .result()
    }
}

/// The control in Control Center. Starting needs the app in the foreground, because location updates have to start
/// there; stopping works in the background.
struct SendingToggleIntent: SetValueIntent, LiveActivityIntent {
    static let title = LocalizedStringResource("Send to optiCLOUD", table: "Shared")
    static let description = IntentDescription(LocalizedStringResource("Starts and stops sending to optiCLOUD.", table: "Shared"))
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    @Parameter(title: LocalizedStringResource("Sending", table: "Shared"))
    var value: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        if value {
            try await continueInForeground(alwaysConfirm: false)
        }
        TransmissionControl.handler?(value)
        return .result()
    }
}

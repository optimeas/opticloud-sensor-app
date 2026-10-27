import AppIntents
import SensorCore

/// Opens the app with the form for a new note (see `docs/spec/journal.md`, Quick note).
struct NewNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "New optiCLOUD Note in the App"
    static let description = IntentDescription("Opens optiCLOUD Sensor with the form for a new note.")
    static let openAppWhenRun = true

    @Dependency private var journal: JournalService

    @MainActor
    func perform() async throws -> some IntentResult {
        journal.isComposing = true
        return .result()
    }
}

/// Saves a note with the text it is given, without opening the app, for example from dictation through Siri.
struct SaveNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "New optiCLOUD Note"
    static let description = IntentDescription("Saves a note with your text on the device of this phone, without opening the app.")

    @Parameter(title: "Text", requestValueDialog: "What should the note say?")
    var text: String

    @Dependency private var journal: JournalService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let item = try await journal.save(title: "", text: text)
        if await journal.waitForDelivery(of: item, timeout: .seconds(10)) {
            return .result(dialog: "The note “\(item.entry.noteName)” is in optiCLOUD.")
        }
        return .result(dialog: "The note “\(item.entry.noteName)” is saved and will be sent to optiCLOUD later.")
    }
}

/// The shortcuts of the app for Siri, Spotlight, the Shortcuts app, and the Action button. "optiCLOUD" is an
/// alternative name of the app in the Info.plist, so that "New optiCLOUD Note" works as a phrase. Phrases that
/// start with the name of the app do not compete with the phrases of the system for its own notes.
struct NoteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SaveNoteIntent(),
            phrases: [
                "New \(.applicationName) Note",
                "\(.applicationName) Note",
                "\(.applicationName) new note",
                "New note in \(.applicationName)",
                "Write a note in \(.applicationName)",
            ],
            shortTitle: "New optiCLOUD Note",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: NewNoteIntent(),
            phrases: [
                "Open a new \(.applicationName) Note",
                "Open a new note in \(.applicationName)",
            ],
            shortTitle: "New Note in the App",
            systemImageName: "note.text.badge.plus"
        )
    }
}

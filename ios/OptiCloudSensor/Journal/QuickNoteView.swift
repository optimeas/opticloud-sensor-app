import SensorCore
import SwiftUI

/// The form for a quick note (see `docs/spec/journal.md`, Quick note): the text first, the title optional, status
/// and priority under "Details" with their defaults.
struct QuickNoteView: View {
    @Environment(AppModel.self) private var app
    @Environment(JournalService.self) private var journal
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var text = ""
    @State private var status = JournalEntry.Status.created
    @State private var priority = JournalEntry.Priority.medium
    @State private var showsDetails = false
    @State private var isSaving = false
    @State private var problem: String?
    @FocusState private var textHasFocus: Bool

    var body: some View {
        NavigationStack {
            Form {
                if app.device == nil || !app.isSignedIn {
                    Section {
                        Label(
                            app.device == nil ? "Choose the device of this phone first." : "Sign in to optiCLOUD to write notes.",
                            systemImage: "person.crop.circle.badge.exclamationmark"
                        )
                        .foregroundStyle(.secondary)
                    }
                }
                Section {
                    TextField("Note", text: $text, axis: .vertical)
                        .lineLimit(4...12)
                        .focused($textHasFocus)
                    TextField("Title (optional)", text: $title)
                } footer: {
                    Text(footer)
                }
                Section {
                    DisclosureGroup("Details", isExpanded: $showsDetails) {
                        Picker("Status", selection: $status) {
                            ForEach(JournalEntry.Status.allCases, id: \.self) { Text($0.title) }
                        }
                        Picker("Priority", selection: $priority) {
                            ForEach(JournalEntry.Priority.allCases, id: \.self) { Text($0.title) }
                        }
                    }
                }
                if let problem {
                    Section {
                        Text(problem).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save", systemImage: "checkmark", role: .confirm) { save() }
                            .disabled(!canSave)
                    }
                }
            }
            .interactiveDismissDisabled(!text.isEmpty || !title.isEmpty)
            .onAppear { textHasFocus = true }
        }
    }

    private var canSave: Bool {
        app.device != nil && app.isSignedIn
            && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Says what the title of the note will be when no title is typed.
    private var footer: String {
        let entry = JournalEntry(title: title, text: text, savedAt: 0, utcOffsetMinutes: 0)
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && entry.canBeSaved {
            return String(localized: "Saved as “\(entry.noteName)”, on the device \(app.device?.name ?? ""), with the time and, if location is allowed, the position.")
        }
        return String(localized: "Saved on the device \(app.device?.name ?? ""), with the time and, if location is allowed, the position.")
    }

    private func save() {
        isSaving = true
        problem = nil
        Task {
            do {
                // The entry is in the queue once this returns; delivery goes on without the form.
                try await journal.save(title: title, text: text, status: status, priority: priority)
                dismiss()
            } catch {
                problem = error.localizedDescription
            }
            isSaving = false
        }
    }
}

extension JournalEntry.Status {
    var title: String {
        switch self {
        case .created: String(localized: "Created", comment: "Status of a note")
        case .archived: String(localized: "Archived", comment: "Status of a note")
        }
    }
}

extension JournalEntry.Priority {
    var title: String {
        switch self {
        case .low: String(localized: "Low", comment: "Priority of a note")
        case .medium: String(localized: "Medium", comment: "Priority of a note")
        case .high: String(localized: "High", comment: "Priority of a note")
        }
    }
}

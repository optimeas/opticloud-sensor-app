import SensorCore
import SwiftUI

/// The notes that wait or were refused, for the test area (see `docs/spec/offline-queue.md`, Journal entries, Status).
struct JournalQueueSection: View {
    @Environment(JournalService.self) private var journal

    var body: some View {
        Section {
            LabeledContent("Waiting", value: journal.waiting.count.formatted())
            LabeledContent("Refused", value: journal.setAside.count.formatted())
            ForEach(journal.items) { item in
                JournalItemRow(item: item, isOtherUser: journal.userId != nil && item.userId != journal.userId)
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) { journal.delete(item) }
                        if item.state != .waiting {
                            Button("Send Again", systemImage: "arrow.clockwise") { journal.retry(item) }
                                .tint(.blue)
                        }
                    }
            }
        } header: {
            Text("Notes")
        } footer: {
            if let reason = journal.stop.reason, !journal.waiting.isEmpty {
                Text(reason)
            }
        }
    }
}

private struct JournalItemRow: View {
    let item: JournalQueue.Item
    let isOtherUser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.entry.noteName)
            Text(Date(timeIntervalSince1970: Double(item.entry.savedAt) / 1000).formatted(date: .abbreviated, time: .shortened))
                .font(.footnote)
                .foregroundStyle(.secondary)
            if case .setAside(let message) = item.state {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.red)
            } else if isOtherUser {
                Text("Waits for the user who wrote it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension JournalQueue.Stop {
    /// Why notes wait, for the user.
    var reason: String? {
        switch self {
        case .done: nil
        case .later: String(localized: "The notes are sent when optiCLOUD can be reached.")
        case .signInNeeded: String(localized: "Sign in to optiCLOUD to send the notes.")
        }
    }
}

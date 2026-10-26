import SensorCore
import SwiftUI

/// A place to check every communication path by hand, and the diagnostic tool for support
/// (see `docs/project-brief.md`, Test area).
struct TestAreaView: View {
    @Environment(AppModel.self) private var app
    @Environment(SensorService.self) private var service

    var body: some View {
        List {
            SendValueSection()
            QueueSection()
            LogSection(log: service.log)
        }
        .navigationTitle("Diagnosis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ShareLink(
                item: DiagnosisReport.text(service: service, app: app),
                subject: Text(verbatim: "optiCLOUD Sensor – \(String(localized: "Diagnosis"))")
            ) {
                Label("Export Log", systemImage: "square.and.arrow.up")
            }
        }
    }
}

/// Writes a single telemetry value or client attribute.
private struct SendValueSection: View {
    enum ValueType: String, CaseIterable, Identifiable {
        case number, text, boolean
        var id: Self { self }

        var label: LocalizedStringKey {
            switch self {
            case .number: "Number"
            case .text: "Text"
            case .boolean: "Yes/No"
            }
        }
    }

    @Environment(SensorService.self) private var service
    @State private var key = "testValue"
    @State private var type = ValueType.number
    @State private var text = ""
    @State private var flag = true

    var body: some View {
        Section {
            TextField("Key", text: $key)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .fontDesign(.monospaced)
            Picker("Type", selection: $type) {
                ForEach(ValueType.allCases) { Text($0.label).tag($0) }
            }
            switch type {
            case .number:
                TextField("Value", text: $text)
                    .keyboardType(.numbersAndPunctuation)
            case .text:
                TextField("Value", text: $text)
            case .boolean:
                Toggle("Value", isOn: $flag)
            }
            Button("Send as Telemetry") {
                guard let value else { return }
                Task { await service.sendTestTelemetry(key: key, value: value) }
            }
            .disabled(!isValidKey || value == nil)
            Button("Send as Client Attribute") {
                guard let value else { return }
                Task { await service.sendTestAttribute(key: key, value: value) }
            }
            .disabled(!isValidKey || value == nil || service.connectionState != .connected)
        } header: {
            Text("Send a Value")
        } footer: {
            Text("Keys are written in lower camel case, for example “testValue”. Telemetry goes through the offline queue; a client attribute needs a connection.")
        }
    }

    private var isValidKey: Bool {
        key.wholeMatch(of: /[a-z][A-Za-z0-9]{0,}/) != nil
    }

    private var value: TelemetryValue? {
        switch type {
        case .number:
            let number = Double(text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
            return number.flatMap { $0.isFinite ? .number($0) : nil }
        case .text:
            return .string(text)
        case .boolean:
            return .bool(flag)
        }
    }
}

/// The state of the offline queue (see `docs/spec/offline-queue.md`, Status).
private struct QueueSection: View {
    @Environment(SensorService.self) private var service

    var body: some View {
        Section("Offline Queue") {
            if let status = service.queueStatus {
                LabeledContent("Samples", value: status.count.formatted())
                LabeledContent("Size", value: Int64(status.bytes).formatted(.byteCount(style: .file)))
                // Always shown: a row that comes and goes with every sample made the list flicker.
                LabeledContent("Oldest", value: status.oldestTs.map {
                    Self.date($0).formatted(date: .abbreviated, time: .standard)
                } ?? "–")
                LabeledContent("Discarded", value: status.discarded.formatted())
                if let from = status.discardedFrom, let to = status.discardedTo {
                    LabeledContent("Discarded Range") {
                        Text(verbatim: "\(Self.date(from).formatted(date: .numeric, time: .shortened)) – \(Self.date(to).formatted(date: .numeric, time: .shortened))")
                    }
                }
                if status.discarded > 0 {
                    Button("Reset Discarded Count") { service.resetDiscardedCount() }
                }
            }
        }
    }

    private static func date(_ ts: Int64) -> Date {
        Date(timeIntervalSince1970: Double(ts) / 1000)
    }
}

/// Commands, shared attributes, problems, and connection changes, the newest first.
private struct LogSection: View {
    let log: TestLog

    var body: some View {
        Section {
            if log.entries.isEmpty {
                Text("Nothing has happened yet. Commands from optiCLOUD and changes of shared attributes appear here.")
                    .foregroundStyle(.secondary)
            }
            ForEach(log.entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label(entry.title, systemImage: entry.kind.symbol)
                            .foregroundStyle(entry.kind == .problem ? .red : .primary)
                        Spacer()
                        Text(entry.timeText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let detail = entry.detail {
                        Text(detail)
                            .font(.footnote)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
        } header: {
            HStack {
                Text("Log")
                Spacer()
                if !log.entries.isEmpty {
                    Button("Clear") { log.clear() }
                        .font(.footnote)
                }
            }
        }
    }
}

extension TestLog.Entry {
    /// The time of the entry, with the day for an entry of an earlier day.
    var timeText: String {
        Calendar.current.isDateInToday(date)
            ? date.formatted(.dateTime.hour().minute().second())
            : date.formatted(.dateTime.day().month().hour().minute().second())
    }
}

private extension TestLog.Entry.Kind {
    var symbol: String {
        switch self {
        case .command: "terminal"
        case .sharedAttribute: "arrow.down.circle"
        case .problem: "exclamationmark.triangle"
        case .connection: "antenna.radiowaves.left.and.right"
        case .sent: "arrow.up.circle"
        case .location: "location"
        case .app: "app"
        }
    }
}

import SensorCore
import SwiftUI

/// The start tab: the state of the phone as a sensor, the central switch for sending, and the values of the
/// last tick, grouped by sensor group.
struct LiveView: View {
    @Environment(AppModel.self) private var app
    @Environment(SensorService.self) private var service

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StatusCard()
                }
                if service.settings.transmitting {
                    ForEach(selectedGroups) { group in
                        GroupValuesSection(group: group, items: items(of: group))
                    }
                } else {
                    Section {
                        Label("The values appear here while the phone is sending.", systemImage: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(app.device?.name ?? "optiCLOUD Sensor")
            .navigationSubtitle(app.device.map { "\($0.tenantName) · \($0.projectName)" } ?? "")
        }
    }

    private var selectedItems: [CatalogItem] {
        service.settings.selection.items(offered: service.offered)
    }

    private var selectedGroups: [CatalogGroup] {
        let keys = Set(selectedItems.map(\.groupKey))
        return Catalog.groups.filter { keys.contains($0.key) }
    }

    private func items(of group: CatalogGroup) -> [CatalogItem] {
        selectedItems.filter { $0.groupKey == group.key }
    }
}

/// Connection, the switch for sending, and what has been sent.
private struct StatusCard: View {
    @Environment(SensorService.self) private var service

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ConnectionStatusLabel(state: service.connectionState)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Label("Every \(service.settings.sendRate) s", systemImage: "metronome")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let problem = service.connectionState.problem {
                Text(problem.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                let start = !service.settings.transmitting
                // Sending without a connection would only fill the queue, so starting also connects.
                if start && !service.settings.connected { service.connect() }
                withAnimation { service.setTransmitting(start) }
            } label: {
                Label(
                    service.settings.transmitting ? "Stop Sending" : "Start Sending",
                    systemImage: service.settings.transmitting ? "stop.fill" : "play.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .tint(service.settings.transmitting ? .red : .accentColor)
            .disabled(!service.canConnect)

            HStack(spacing: 16) {
                if let since = service.transmittingSince {
                    Statistic(value: since.formatted(date: .omitted, time: .shortened), label: "Sending since")
                    Statistic(value: "\(service.samplesSinceStart)", label: "Samples")
                }
                Statistic(value: "\(service.queueStatus?.count ?? 0)", label: "Waiting")
            }
        }
        .padding(.vertical, 6)
    }
}

private struct Statistic: View {
    let value: String
    let label: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// The values of one group at the last tick.
private struct GroupValuesSection: View {
    @Environment(SensorService.self) private var service
    let group: CatalogGroup
    let items: [CatalogItem]

    var body: some View {
        Section {
            ForEach(items) { item in
                LabeledContent {
                    ValueText(item: item, values: service.liveValues)
                } label: {
                    Text(item.title)
                }
            }
        } header: {
            Label(group.title, systemImage: group.symbol)
        } footer: {
            if group.key == "sound" {
                Text("Measured only while the app is open.")
            }
        }
    }
}

/// The value of an item as it was sent: the means of aggregated values with their range below.
private struct ValueText: View {
    let item: CatalogItem
    let values: [String: TelemetryValue]

    var body: some View {
        let main = item.valueKeys.compactMap { key in values[key].map { (key, $0) } }
        if main.isEmpty {
            Text("–").foregroundStyle(.tertiary)
        } else {
            VStack(alignment: .trailing, spacing: 2) {
                Text(main.map { ValueFormat.text($0.1, key: $0.0, item: item, withUnit: main.count == 1) }
                    .joined(separator: "  ") + (main.count > 1 ? unitSuffix : ""))
                    .monospacedDigit()
                if item.kind == .aggregated, item.valueKeys.count == 1, let range = range(item.valueKeys[0]) {
                    Text(range)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var unitSuffix: String {
        let unit = ValueFormat.unit(item)
        return unit.isEmpty ? "" : " " + unit
    }

    private func range(_ key: String) -> String? {
        guard let min = values[key + "Min"], let max = values[key + "Max"] else { return nil }
        return "\(ValueFormat.text(min, key: key + "Min", item: item, withUnit: false)) – \(ValueFormat.text(max, key: key + "Max", item: item, withUnit: true))"
    }
}

/// How the live view writes values: with the decimals of the resolution and the unit of the catalog.
enum ValueFormat {
    static func text(_ value: TelemetryValue, key: String, item: CatalogItem, withUnit: Bool) -> String {
        switch value {
        case .bool(let on):
            return on ? String(localized: "Yes") : String(localized: "No")
        case .string(let text):
            return text
        case .number(let number):
            if item.key == "batteryLevel" { return number.formatted(.percent.precision(.fractionLength(0))) }
            if item.key == "dataVolume" { return Int64(number).formatted(.byteCount(style: .file)) }
            let decimals = max(0, -(item.resolution?.exponent ?? 0))
            let text = number.formatted(.number.precision(.fractionLength(decimals)))
            let unit = unit(item)
            return withUnit && !unit.isEmpty ? "\(text) \(unit)" : text
        }
    }

    static func unit(_ item: CatalogItem) -> String {
        switch item.unit {
        case "", "count", "string", "boolean", "B": ""
        default: item.unit
        }
    }
}

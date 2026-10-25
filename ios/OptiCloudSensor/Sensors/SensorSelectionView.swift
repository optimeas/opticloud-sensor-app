import SensorCore
import SwiftUI

/// The sensor selection (see `docs/spec/sensors.md`, Selection): whole groups are switched on and off, and a group
/// can be opened to deselect single items. Only what this phone offers is shown.
struct SensorSelectionView: View {
    @Environment(SensorService.self) private var service

    var body: some View {
        List {
            Section {
                ForEach(groups) { group in
                    NavigationLink {
                        SensorGroupView(group: group)
                    } label: {
                        Toggle(isOn: groupBinding(group)) {
                            VStack(alignment: .leading) {
                                Text(group.title)
                                Text(summary(of: group))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(isManaged)
                    }
                }
            } footer: {
                if isManaged {
                    Text("optiCLOUD manages the selection of this device. Change it there.")
                } else {
                    Text("A sensor that needs a permission asks for it when transmission starts.")
                }
            }
        }
        .navigationTitle("Sensors")
    }

    private var isManaged: Bool { service.settings.managed.contains("sensors") }

    private var groups: [CatalogGroup] {
        Catalog.groups.filter { group in group.items.contains { service.offered.contains($0.key) } }
    }

    private func summary(of group: CatalogGroup) -> String {
        let offered = group.items.filter { service.offered.contains($0.key) }
        let selected = offered.filter { service.settings.selection.itemKeys.contains($0.key) }
        return String(localized: "\(selected.count) of \(offered.count) selected")
    }

    private func groupBinding(_ group: CatalogGroup) -> Binding<Bool> {
        let keys = Set(group.items.map(\.key)).intersection(service.offered)
        return Binding(
            get: { !service.settings.selection.itemKeys.isDisjoint(with: keys) },
            set: { on in
                var selected = service.settings.selection.itemKeys
                if on { selected.formUnion(keys) } else { selected.subtract(keys) }
                service.setSelection(Selection(itemKeys: selected))
            }
        )
    }
}

private struct SensorGroupView: View {
    @Environment(SensorService.self) private var service
    let group: CatalogGroup

    var body: some View {
        List {
            ForEach(group.items.filter { service.offered.contains($0.key) }) { item in
                Toggle(isOn: binding(item)) {
                    VStack(alignment: .leading) {
                        Text(item.title)
                        Text(item.valueKeys.joined(separator: ", "))
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(service.settings.managed.contains("sensors"))
            }
        }
        .navigationTitle(group.title)
    }

    private func binding(_ item: CatalogItem) -> Binding<Bool> {
        Binding(
            get: { service.settings.selection.itemKeys.contains(item.key) },
            set: { on in
                var selected = service.settings.selection.itemKeys
                if on { selected.insert(item.key) } else { selected.remove(item.key) }
                service.setSelection(Selection(itemKeys: selected))
            }
        )
    }
}

extension CatalogGroup {
    var title: String {
        switch key {
        case "motion": String(localized: "Motion")
        case "environment": String(localized: "Environment")
        case "location": String(localized: "Location")
        case "activity": String(localized: "Activity")
        case "device": String(localized: "Device")
        case "sound": String(localized: "Sound")
        case "health": String(localized: "Health")
        default: key
        }
    }
}

extension CatalogItem {
    var title: String {
        switch key {
        case "accel": String(localized: "Acceleration")
        case "accelMagnitude": String(localized: "Acceleration Magnitude")
        case "gyro": String(localized: "Rotation Rate")
        case "mag": String(localized: "Magnetic Field")
        case "orientation": String(localized: "Orientation")
        case "pressure": String(localized: "Air Pressure")
        case "light": String(localized: "Ambient Light")
        case "position": String(localized: "Position")
        case "altitude": String(localized: "Altitude")
        case "speed": String(localized: "Speed")
        case "course": String(localized: "Course")
        case "locationAccuracy": String(localized: "Location Accuracy")
        case "steps": String(localized: "Steps Today")
        case "activityType": String(localized: "Kind of Activity")
        case "batteryLevel": String(localized: "Battery Level")
        case "charging": String(localized: "Charging")
        case "network": String(localized: "Network")
        case "thermalState": String(localized: "Thermal State")
        case "powerSaving": String(localized: "Low Power Mode")
        case "cellularSignal": String(localized: "Signal Strength")
        case "dataVolume": String(localized: "Data Volume")
        case "soundLevel": String(localized: "Sound Level")
        default: key
        }
    }
}

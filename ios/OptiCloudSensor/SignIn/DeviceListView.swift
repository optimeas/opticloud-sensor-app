import SensorCore
import SwiftUI

/// Step 6: the device the phone sends to, or a new one.
struct DeviceListView: View {
    @Bindable var model: SignInModel
    @State private var takeOverCandidate: DeviceRow?
    @State private var isCreating = false

    var body: some View {
        List {
            Section {
                if model.devices.isEmpty && !model.isWorking {
                    Text("There is no device of the app in this project yet.")
                        .foregroundStyle(.secondary)
                }
                ForEach(model.devices) { row in
                    Button {
                        if row.binding == .otherPhone {
                            takeOverCandidate = row
                        } else {
                            Task { await model.choose(row) }
                        }
                    } label: {
                        DeviceRowLabel(row: row)
                    }
                    .disabled(model.isWorking)
                }
            } footer: {
                Text("Only devices of the type “\(SensorCore.deviceType)” are listed.")
            }

            Section {
                Button("New Device", systemImage: "plus") {
                    isCreating = true
                }
                .disabled(model.isWorking)
            }
        }
        .overlay {
            if model.isWorking { ProgressView() }
        }
        .refreshable { await model.refreshDevices() }
        .navigationTitle("Device")
        .confirmationDialog(
            "Take Over Device?",
            isPresented: Binding(get: { takeOverCandidate != nil }, set: { if !$0 { takeOverCandidate = nil } }),
            titleVisibility: .visible,
            presenting: takeOverCandidate
        ) { row in
            Button("Take Over", role: .destructive) {
                Task { await model.choose(row, takeOver: true) }
            }
        } message: { row in
            Text("“\(row.device.name)” is bound to another phone. If you take it over, the other phone stops sending to this device.")
        }
        .sheet(isPresented: $isCreating) {
            NewDeviceView(model: model)
        }
    }
}

private struct DeviceRowLabel: View {
    let row: DeviceRow

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(row.device.name)
                    .foregroundStyle(row.binding == .otherPhone ? .secondary : .primary)
                if let status {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if row.binding == .thisPhone {
                Image(systemName: "iphone")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            } else if row.binding == .otherPhone {
                Image(systemName: "lock")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }

    private var status: String? {
        switch row.binding {
        case .free: nil
        case .thisPhone: String(localized: "Bound to this phone")
        case .otherPhone: String(localized: "Bound to another phone")
        case .unknown: String(localized: "Binding unknown")
        }
    }
}

/// Creates a device with a name the user can change.
private struct NewDeviceView: View {
    @Bindable var model: SignInModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $model.newDeviceName)
                        .focused($focused)
                        .submitLabel(.done)
                } footer: {
                    Text("The name must be unique in the tenant.")
                }
            }
            .navigationTitle("New Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if model.isWorking {
                        ProgressView()
                    } else {
                        Button("Create") {
                            Task {
                                await model.createDevice()
                                if model.error == nil { dismiss() }
                            }
                        }
                        .disabled(model.newDeviceName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}

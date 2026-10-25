import SensorCore
import SwiftUI

/// The settings tab: device and account, connection, transmission, and information about the app.
struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(SensorService.self) private var service
    @State private var isSigningIn = false
    @State private var isConfirmingDeviceChange = false

    var body: some View {
        NavigationStack {
            List {
                deviceSection
                ConnectionSection()
                TransmissionSection()
                accountSection
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About optiCLOUD Sensor", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $isSigningIn) {
            SignInView(app: app)
        }
        .confirmationDialog(
            "Choose Another Device?",
            isPresented: $isConfirmingDeviceChange,
            titleVisibility: .visible
        ) {
            Button("Choose Another Device", role: .destructive) { isSigningIn = true }
        } message: {
            Text("^[\(service.queueStatus?.count ?? 0) sample](inflect: true) have not been delivered yet. They are discarded when you pick another device.")
        }
    }

    @ViewBuilder private var deviceSection: some View {
        if let device = app.device {
            Section("Device") {
                LabeledContent("Device", value: device.name)
                LabeledContent("Project", value: device.projectName)
                LabeledContent("Tenant", value: device.tenantName)
                LabeledContent("Server", value: app.address.host)
                Button("Choose Another Device") {
                    if (service.queueStatus?.count ?? 0) > 0 {
                        isConfirmingDeviceChange = true
                    } else {
                        isSigningIn = true
                    }
                }
            }
        }
    }

    @ViewBuilder private var accountSection: some View {
        Section {
            if app.isSignedIn {
                Button("Sign Out", role: .destructive) { app.signOut() }
            } else {
                Button("Sign In") { isSigningIn = true }
            }
        } header: {
            Text("Account")
        } footer: {
            Text(app.isSignedIn
                ? "Signing out does not stop sending to the device."
                : "Not signed in. The journal needs a signed-in user.")
        }
    }
}

private struct ConnectionSection: View {
    @Environment(SensorService.self) private var service

    var body: some View {
        Section {
            Toggle(isOn: Binding(
                get: { service.settings.connected },
                set: { $0 ? service.connect() : service.disconnect() }
            )) {
                Label("Connected", systemImage: "link")
            }
            .disabled(!service.canConnect)
            LabeledContent("Status") {
                ConnectionStatusLabel(state: service.connectionState)
            }
        } header: {
            Text("Connection")
        } footer: {
            if let problem = service.connectionState.problem {
                Text(problem.explanation)
            } else {
                Text("While connected, optiCLOUD can send commands to the phone, also when it is not sending.")
            }
        }
    }
}

private struct TransmissionSection: View {
    @Environment(SensorService.self) private var service

    var body: some View {
        Section {
            if service.settings.managed.contains("sendRate") {
                LabeledContent {
                    Text("Every \(service.settings.sendRate) s · managed")
                } label: {
                    Label("Send Rate", systemImage: "metronome")
                }
            } else {
                Stepper(value: Binding(
                    get: { service.settings.sendRate },
                    set: { service.setSendRate($0) }
                ), in: TransmissionSettings.sendRates) {
                    LabeledContent {
                        Text("Every \(service.settings.sendRate) s")
                    } label: {
                        Label("Send Rate", systemImage: "metronome")
                    }
                }
            }
            Picker(selection: Binding(
                get: { service.settings.sendMode },
                set: { service.setSendMode($0) }
            )) {
                Text("On Change").tag(SendMode.onChange)
                Text("Every Tick").tag(SendMode.everyTick)
            } label: {
                Label("Send", systemImage: "arrow.up.arrow.down")
            }
            NavigationLink {
                SensorSelectionView()
            } label: {
                LabeledContent {
                    Text(service.settings.selection.reported(offered: service.offered))
                } label: {
                    Label("Sensors", systemImage: "sensor")
                }
            }
            if !service.settings.selection.items(offered: LocationSampler.offered).isEmpty {
                LocationPermissionRow(location: service.location)
            }
            NavigationLink {
                DataVolumeView(counter: service.dataVolume)
            } label: {
                LabeledContent {
                    let today = service.dataVolume.total(.today)
                    Text(today.mobile + today.wifi, format: .byteCount(style: .file))
                } label: {
                    Label("Data Volume Today", systemImage: "chart.bar")
                }
            }
        } header: {
            Text("Transmission")
        } footer: {
            Text("On change sends a value only when it has changed, and all values once a minute. While location is in use, the app goes on sending in the background; iOS shows this in the status bar. The sound level is measured only while the app is open. To stop sending in the background, stop sending on the Live tab; swiping the app away is not enough.")
        }
    }
}

private struct LocationPermissionRow: View {
    let location: LocationSampler
    @Environment(\.openURL) private var openURL

    var body: some View {
        LabeledContent {
            switch location.authorization {
            case .authorizedAlways: Text("Always")
            case .authorizedWhenInUse: Text("While Using the App")
            case .notDetermined: Text("Asked When Sending")
            default:
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
        } label: {
            Label("Location Access", systemImage: "location")
        }
    }
}

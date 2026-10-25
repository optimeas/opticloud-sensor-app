import SensorCore
import SwiftUI

/// The start screen: the selected device, connection, transmission, and the account.
struct ContentView: View {
    @Environment(AppModel.self) private var app
    @Environment(SensorService.self) private var service
    @State private var isSigningIn = false
    @State private var isConfirmingDeviceChange = false

    var body: some View {
        NavigationStack {
            Group {
                if let device = app.device {
                    List {
                        ConnectionSection()
                        TransmissionSection()
                        Section {
                            NavigationLink("Test Area") { TestAreaView() }
                        }
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
                        accountSection
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Device", systemImage: "sensor")
                    } description: {
                        Text("Sign in to optiCLOUD and choose the device this phone sends to.")
                    } actions: {
                        Button(app.isSignedIn ? "Choose Device" : "Sign In") { isSigningIn = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("optiCLOUD Sensor")
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
            Toggle("Connected", isOn: Binding(
                get: { service.settings.connected },
                set: { $0 ? service.connect() : service.disconnect() }
            ))
            .disabled(!service.canConnect)
            LabeledContent("Status") {
                ConnectionStatusLabel(state: service.connectionState)
            }
        } header: {
            Text("Connection")
        } footer: {
            if let problem = service.connectionState.problem {
                Text(problem.explanation)
            }
        }
    }
}

private struct ConnectionStatusLabel: View {
    let state: ConnectionState

    var body: some View {
        switch state {
        case .disconnected:
            Text("Disconnected")
        case .connecting:
            HStack(spacing: 6) {
                ProgressView()
                Text("Connecting")
            }
        case .connected:
            Label("Connected", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .waiting:
            Text("Waiting")
        case .refused:
            Label("Refused", systemImage: "xmark.octagon.fill")
                .foregroundStyle(.red)
        }
    }
}

private struct TransmissionSection: View {
    @Environment(SensorService.self) private var service

    var body: some View {
        Section {
            Toggle("Transmit", isOn: Binding(
                get: { service.settings.transmitting },
                set: { service.setTransmitting($0) }
            ))
            if service.settings.managed.contains("sendRate") {
                LabeledContent("Send Rate") {
                    Text("Every \(service.settings.sendRate) s · managed")
                }
            } else {
                Stepper(value: Binding(
                    get: { service.settings.sendRate },
                    set: { service.setSendRate($0) }
                ), in: TransmissionSettings.sendRates) {
                    LabeledContent("Send Rate", value: "Every \(service.settings.sendRate) s")
                }
            }
            LabeledContent("Sensors", value: service.settings.selection.reported(offered: service.offered))
            if !service.settings.selection.items(offered: LocationSampler.offered).isEmpty {
                LocationPermissionRow(location: service.location)
            }
            if let status = service.queueStatus {
                LabeledContent("Waiting to Be Sent", value: "\(status.count)")
            }
        } header: {
            Text("Transmission")
        } footer: {
            Text("Samples wait on the phone while there is no connection and are sent when it is back. While location is in use, the app goes on sending in the background; iOS shows this in the status bar.")
        }
    }
}

private struct LocationPermissionRow: View {
    let location: LocationSampler
    @Environment(\.openURL) private var openURL

    var body: some View {
        LabeledContent("Location Access") {
            switch location.authorization {
            case .authorizedAlways: Text("Always")
            case .authorizedWhenInUse: Text("While Using the App")
            case .notDetermined: Text("Asked When Transmitting")
            default:
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
        }
    }
}

private extension ConnectionProblem {
    var explanation: LocalizedStringKey {
        switch self {
        case .noNetwork: "No network. The app connects again when the network is back."
        case .serverNotReachable: "The server cannot be reached."
        case .certificateNotTrusted: "The certificate of the server is not trusted."
        case .connectionLost: "The connection was lost."
        case .tokenRefused: "The server refused the access token of the device. Choose the device again."
        case .boundToAnotherPhone: "Another phone has taken over this device. Choose the device again to take it back."
        case .notBound: "The device is not bound to this phone. Sign in and choose the device again."
        }
    }
}

#Preview {
    let app = AppModel()
    ContentView()
        .environment(app)
        .environment(SensorService(app: app))
}

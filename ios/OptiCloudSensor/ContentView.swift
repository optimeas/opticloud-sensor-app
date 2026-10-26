import SensorCore
import SwiftUI

/// The root of the app: without a device it leads to sign-in; with one it shows the tabs.
struct ContentView: View {
    @Environment(AppModel.self) private var app
    @State private var isSigningIn = false
    /// The tab opens again where the user left it.
    @AppStorage("selectedTab") private var selectedTab = "live"

    var body: some View {
        Group {
            if app.device != nil {
                TabView(selection: $selectedTab) {
                    Tab("Live", systemImage: "dot.radiowaves.left.and.right", value: "live") {
                        LiveView()
                    }
                    Tab("Diagnosis", systemImage: "stethoscope", value: "diagnosis") {
                        NavigationStack { TestAreaView() }
                    }
                    Tab("Settings", systemImage: "gearshape", value: "settings") {
                        SettingsView()
                    }
                }
            } else {
                NavigationStack {
                    ContentUnavailableView {
                        Label("No Device", systemImage: "sensor")
                    } description: {
                        Text("Sign in to optiCLOUD and choose the device this phone sends to.")
                    } actions: {
                        Button(app.isSignedIn ? "Choose Device" : "Sign In") { isSigningIn = true }
                            .buttonStyle(.glassProminent)
                            .controlSize(.large)
                    }
                    .navigationTitle("optiCLOUD Sensor")
                }
            }
        }
        .sheet(isPresented: $isSigningIn) {
            SignInView(app: app)
        }
    }
}

/// The connection state as a short label with a symbol and its color.
struct ConnectionStatusLabel: View {
    let state: ConnectionState

    var body: some View {
        switch state {
        case .disconnected:
            Label("Disconnected", systemImage: "bolt.horizontal.circle")
                .foregroundStyle(.secondary)
        case .connecting:
            HStack(spacing: 6) {
                ProgressView()
                Text("Connecting")
            }
        case .connected:
            Label("Connected", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .waiting:
            Label("Waiting", systemImage: "clock.arrow.circlepath")
                .foregroundStyle(.orange)
        case .refused:
            Label("Refused", systemImage: "xmark.octagon.fill")
                .foregroundStyle(.red)
        }
    }
}

extension ConnectionState {
    /// The state as a word, for the diagnosis report.
    var title: String {
        switch self {
        case .disconnected: String(localized: "Disconnected")
        case .connecting: String(localized: "Connecting")
        case .connected: String(localized: "Connected")
        case .waiting: String(localized: "Waiting")
        case .refused: String(localized: "Refused")
        }
    }
}

extension ConnectionProblem {
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

extension CatalogGroup {
    /// The SF Symbol of the group.
    var symbol: String {
        switch key {
        case "motion": "gyroscope"
        case "environment": "barometer"
        case "location": "location.fill"
        case "activity": "figure.walk"
        case "device": "iphone"
        case "sound": "waveform"
        case "health": "heart.fill"
        case "test": "waveform.path.ecg"
        default: "sensor"
        }
    }
}

#Preview {
    let app = AppModel()
    ContentView()
        .environment(app)
        .environment(SensorService(app: app))
}

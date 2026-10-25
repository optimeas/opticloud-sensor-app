import SensorCore
import SwiftUI

/// The start screen: the selected device and the account. Connection and transmission follow.
struct ContentView: View {
    @Environment(AppModel.self) private var app
    @State private var isSigningIn = false

    var body: some View {
        NavigationStack {
            Group {
                if let device = app.device {
                    List {
                        Section("Device") {
                            LabeledContent("Device", value: device.name)
                            LabeledContent("Project", value: device.projectName)
                            LabeledContent("Tenant", value: device.tenantName)
                            LabeledContent("Server", value: app.address.host)
                        }
                        Section {
                            Button("Choose Another Device") { isSigningIn = true }
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

#Preview {
    ContentView()
        .environment(AppModel())
}

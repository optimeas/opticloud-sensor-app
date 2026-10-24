import SensorCore
import SwiftUI

/// Placeholder until sign-in and device selection exist.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "optiCLOUD Sensor",
                systemImage: "sensor",
                description: Text("Sign-in and device selection follow.")
            )
            .navigationTitle("optiCLOUD Sensor")
        }
    }
}

#Preview {
    ContentView()
}

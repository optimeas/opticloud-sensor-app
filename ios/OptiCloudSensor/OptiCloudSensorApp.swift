import SwiftUI

@main
struct OptiCloudSensorApp: App {
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(app)
        }
    }
}

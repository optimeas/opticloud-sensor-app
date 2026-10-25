import SwiftUI

@main
struct OptiCloudSensorApp: App {
    @State private var app: AppModel
    @State private var service: SensorService

    init() {
        let app = AppModel()
        _app = State(initialValue: app)
        _service = State(initialValue: SensorService(app: app))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(app)
                .environment(service)
        }
    }
}

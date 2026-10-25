import SwiftUI

@main
struct OptiCloudSensorApp: App {
    @UIApplicationDelegateAdaptor private var delegate: AppDelegate
    @State private var app: AppModel
    @State private var service: SensorService

    init() {
        let dataVolume = DataVolumeCounter()
        let app = AppModel(transport: CountingTransport(counter: dataVolume))
        _app = State(initialValue: app)
        _service = State(initialValue: SensorService(app: app, dataVolume: dataVolume))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(app)
                .environment(service)
        }
    }
}

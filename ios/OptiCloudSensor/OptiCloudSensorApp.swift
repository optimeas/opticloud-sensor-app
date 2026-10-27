import AppIntents
import SwiftUI

@main
struct OptiCloudSensorApp: App {
    @State private var app: AppModel
    @State private var service: SensorService
    @State private var journal: JournalService

    init() {
        let dataVolume = DataVolumeCounter()
        let app = AppModel(transport: CountingTransport(counter: dataVolume))
        let service = SensorService(app: app, dataVolume: dataVolume)
        let journal = JournalService(app: app, location: service.location, log: service.log)
        _app = State(initialValue: app)
        _service = State(initialValue: service)
        _journal = State(initialValue: journal)
        // The App Shortcuts of the journal reach the service through this.
        AppDependencyManager.shared.add(dependency: journal)
        NoteShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(app)
                .environment(service)
                .environment(journal)
        }
    }
}

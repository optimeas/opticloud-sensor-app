import AppIntents
import SwiftUI
import WidgetKit

/// Starts and stops sending from Control Center, the Lock Screen, or the Action button.
struct SendingControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: SharedState.sendingControlKind, provider: Provider()) { isOn in
            ControlWidgetToggle("Send to optiCLOUD", isOn: isOn, action: SendingToggleIntent()) { isOn in
                // The cloud of the app icon: with its pulse while sending, with a flat line when off.
                Label(isOn ? "Sending" : "Off", image: isOn ? "opticloud.pulse" : "opticloud.off")
            }
            .tint(.green)
        }
        .displayName("Send to optiCLOUD")
        .description("Starts and stops sending to your device in optiCLOUD.")
    }

    struct Provider: ControlValueProvider {
        var previewValue: Bool { false }

        func currentValue() async throws -> Bool {
            SharedState.isTransmitting
        }
    }
}

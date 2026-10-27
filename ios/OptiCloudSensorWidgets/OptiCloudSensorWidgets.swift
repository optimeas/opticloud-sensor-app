import SwiftUI
import WidgetKit

/// The widget extension: the Live Activity while sending and the control in Control Center.
@main
struct OptiCloudSensorWidgets: WidgetBundle {
    var body: some Widget {
        SendingLiveActivity()
        SendingControl()
    }
}

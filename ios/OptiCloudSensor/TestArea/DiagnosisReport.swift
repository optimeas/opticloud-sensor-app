import SensorCore
import UIKit

/// The diagnosis as text to pass on, for example to support: the app and the phone, the device and the settings,
/// the offline queue, and the log. It holds no access token and no password.
enum DiagnosisReport {
    static func text(service: SensorService, app: AppModel) -> String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        let settings = service.settings
        var lines = [
            "optiCLOUD Sensor \(version) (\(build))",
            "\(DeviceModel.current), iOS \(UIDevice.current.systemVersion)",
            Date.now.formatted(date: .numeric, time: .standard),
            "",
        ]
        if let device = app.device {
            lines.append("\(String(localized: "Device")): \(device.name) · \(device.projectName) · \(device.tenantName)")
        }
        lines.append("\(String(localized: "Server")): \(app.address.host)")
        var connection = "\(String(localized: "Connection")): \(service.connectionState.title)"
        if let problem = service.connectionState.problem { connection += " (\(problem.rawValue))" }
        lines.append(connection)
        let mode = settings.sendMode == .onChange ? String(localized: "On Change") : String(localized: "Every Tick")
        lines.append("\(String(localized: "Transmission")): \(settings.transmitting ? String(localized: "Yes") : String(localized: "No")), \(String(localized: "Every \(settings.sendRate) s")), \(mode)")
        lines.append("\(String(localized: "Sensors")): \(settings.selection.reported(offered: service.offered))")
        if let status = service.queueStatus {
            lines.append("\(String(localized: "Offline Queue")): \(status.count) \(String(localized: "Samples")), \(status.discarded) \(String(localized: "Discarded"))")
        }
        lines += ["", String(localized: "Log")]
        for entry in service.log.entries {
            lines.append("\(entry.date.formatted(.dateTime.hour().minute().second()))  \(entry.title)")
            if let detail = entry.detail {
                lines += detail.split(separator: "\n", omittingEmptySubsequences: false).map { "          \($0)" }
            }
        }
        return lines.joined(separator: "\n")
    }
}

import SensorCore
import SwiftUI

/// The app's own data volume, today, this week, and this month (see `docs/spec/connection.md`, Data volume).
struct DataVolumeView: View {
    let counter: DataVolumeCounter

    var body: some View {
        List {
            period("Today", counter.total(.today))
            period("This Week", counter.total(.week))
            period("This Month", counter.total(.month))
            Section {
            } footer: {
                Text("An estimate: the app counts what it sends and receives, and adds an allowance for encryption and the network protocols. Your carrier may count differently.")
            }
        }
        .navigationTitle("Data Volume")
    }

    private func period(_ title: LocalizedStringKey, _ counters: DataVolume.Counters) -> some View {
        Section(title) {
            row("Mobile Network", sent: counters.mobileSent, received: counters.mobileReceived)
            row("Wi-Fi", sent: counters.wifiSent, received: counters.wifiReceived)
        }
    }

    private func row(_ title: LocalizedStringKey, sent: Int64, received: Int64) -> some View {
        LabeledContent(title) {
            VStack(alignment: .trailing) {
                Text(sent + received, format: .byteCount(style: .file))
                Text("↑ \(sent.formatted(.byteCount(style: .file)))  ↓ \(received.formatted(.byteCount(style: .file)))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

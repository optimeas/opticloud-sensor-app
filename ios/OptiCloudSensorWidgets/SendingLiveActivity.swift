import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The Live Activity on the Lock Screen and in the Dynamic Island while the phone sends.
struct SendingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SendingAttributes.self) { context in
            LockScreenView(context: context)
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            let phase = context.state.phase
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(phase.title)
                    } icon: {
                        Image(systemName: phase.symbol)
                    }
                    .font(.headline)
                    .foregroundStyle(phase.color)
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Elapsed(since: context.attributes.since)
                        .font(.headline)
                        .frame(maxWidth: 80, alignment: .trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.deviceName)
                                .font(.subheadline)
                            WaitingText(waiting: context.state.waiting)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StopButton()
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                CloudPulse(phase: phase)
            } compactTrailing: {
                Elapsed(since: context.attributes.since)
                    .frame(maxWidth: 52)
            } minimal: {
                CloudPulse(phase: phase)
            }
            .keylineTint(phase.color)
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<SendingAttributes>

    var body: some View {
        let phase = context.state.phase
        HStack(alignment: .center, spacing: 14) {
            Image("AppLogo")
                .resizable()
                .frame(width: 44, height: 44)
                .clipShape(.rect(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Label {
                    Text(phase.title)
                } icon: {
                    Image(systemName: phase.symbol)
                }
                .font(.headline)
                .foregroundStyle(phase.color)
                Text(context.attributes.deviceName)
                    .font(.subheadline)
                WaitingText(waiting: context.state.waiting)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 8) {
                Elapsed(since: context.attributes.since)
                    .font(.title3.weight(.semibold))
                StopButton()
            }
        }
        .padding(16)
    }
}

/// The cloud of the app icon in the color of the phase, for the small spaces of the Dynamic Island. While it does not
/// send, a badge shows why.
private struct CloudPulse: View {
    let phase: SendingAttributes.Phase

    var body: some View {
        Image("opticloud.pulse")
            .foregroundStyle(phase.color)
            .overlay(alignment: .bottomTrailing) {
                if let badge = phase.badge {
                    Image(systemName: badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.black, phase.color)
                        .offset(x: 4, y: 3)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text(phase.title))
    }
}

/// The time since transmission started, counted by the system.
private struct Elapsed: View {
    let since: Date

    var body: some View {
        Text(timerInterval: since...since.addingTimeInterval(7 * 24 * 3600), countsDown: false)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
}

private struct WaitingText: View {
    let waiting: Int

    var body: some View {
        if waiting > 0 {
            Text("\(waiting) values waiting")
        } else {
            Text("All values delivered")
        }
    }
}

private struct StopButton: View {
    var body: some View {
        Button(intent: StopSendingIntent()) {
            Label("Stop", systemImage: "stop.fill")
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
    }
}

extension SendingAttributes.Phase {
    var badge: String? {
        switch self {
        case .sending: nil
        case .waiting: "clock.fill"
        case .refused: "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .sending: .green
        case .waiting: .orange
        case .refused: .red
        }
    }
}

#Preview("Lock Screen", as: .content, using: SendingAttributes(deviceName: "iPhone-16promax", since: .now.addingTimeInterval(-4000))) {
    SendingLiveActivity()
} contentStates: {
    SendingAttributes.ContentState(phase: .sending, waiting: 0)
    SendingAttributes.ContentState(phase: .waiting, waiting: 42)
}

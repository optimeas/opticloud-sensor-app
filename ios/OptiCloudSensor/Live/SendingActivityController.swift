import ActivityKit
import Foundation
import Observation
import SensorCore
import UIKit
import WidgetKit

/// Shows the state of transmission outside the app (see `docs/spec/connection.md`, Status outside the app): the Live
/// Activity on the Lock Screen and in the Dynamic Island, and the control in Control Center.
final class SendingActivityController {
    private let app: AppModel
    private let service: SensorService
    private var activity: Activity<SendingAttributes>?
    private var shown: SendingAttributes.ContentState?
    private var shownAt = Date.distantPast

    /// A change of the number of waiting values alone updates the Live Activity at most this often.
    static let countInterval: TimeInterval = 15

    init(app: AppModel, service: SensorService) {
        self.app = app
        self.service = service
        activity = Activity<SendingAttributes>.activities.first
        TransmissionControl.handler = { [weak service] on in service?.setTransmitting(on) }
        observe()
        observeForeground()
        refresh()
    }

    private func observe() {
        withObservationTracking {
            _ = service.settings.transmitting
            _ = service.connectionState
            _ = service.queueStatus?.count
            _ = app.device?.name
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.refresh()
                self?.observe()
            }
        }
    }

    /// A Live Activity can only start while the app is in the foreground, and iOS ends it after eight hours. When the
    /// app comes to the foreground, a new one starts if transmission is still on.
    private func observeForeground() {
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification) {
                self?.refresh()
            }
        }
    }

    private func refresh() {
        let transmitting = service.settings.transmitting
        if SharedState.isTransmitting != transmitting {
            SharedState.isTransmitting = transmitting
            ControlCenter.shared.reloadControls(ofKind: SharedState.sendingControlKind)
        }
        guard transmitting, let device = app.device else {
            end()
            return
        }
        let state = SendingAttributes.ContentState(phase: phase, waiting: service.queueStatus?.count ?? 0)
        if let activity, activity.activityState == .active, activity.attributes.deviceName == device.name {
            guard state != shown,
                  state.phase != shown?.phase || Date().timeIntervalSince(shownAt) >= Self.countInterval
            else { return }
            show(state)
            let id = activity.id
            Task { await Self.update(id: id, to: state) }
        } else {
            guard UIApplication.shared.applicationState == .active,
                  ActivityAuthorizationInfo().areActivitiesEnabled
            else { return end() }
            let attributes = SendingAttributes(deviceName: device.name, since: service.transmittingSince ?? Date())
            activity = try? Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: nil))
            show(state)
            // An activity that ended or belongs to another device goes.
            let id = activity?.id
            Task { await Self.endAll(except: id) }
        }
    }

    private func show(_ state: SendingAttributes.ContentState) {
        shown = state
        shownAt = Date()
    }

    private func end() {
        guard activity != nil || !Activity<SendingAttributes>.activities.isEmpty else { return }
        activity = nil
        shown = nil
        Task { await Self.endAll(except: nil) }
    }

    // Activity is not Sendable; these look it up where they use it.

    private nonisolated static func update(id: String, to state: SendingAttributes.ContentState) async {
        guard let activity = Activity<SendingAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    private nonisolated static func endAll(except id: String?) async {
        for activity in Activity<SendingAttributes>.activities where activity.id != id {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private var phase: SendingAttributes.Phase {
        switch service.connectionState {
        case .connected: .sending
        case .refused: .refused
        case .disconnected, .connecting, .waiting: .waiting
        }
    }
}

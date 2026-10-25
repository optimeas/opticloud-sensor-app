import DeviceLink
import Foundation
import Observation
import SensorCore
import UIKit

/// The service layer: samples the selected sensors, puts the samples into the offline queue, and keeps the
/// connection that delivers them. It does not depend on the user interface.
@Observable
final class SensorService {
    private let app: AppModel
    private let defaults: UserDefaults
    private let sampler = DeviceSampler()
    private let queue: TelemetryQueue
    @ObservationIgnored private var link: DeviceLink!
    /// Calls to the connection, kept in order.
    @ObservationIgnored private var linkCalls: Task<Void, Never>?
    @ObservationIgnored private var ticks: Task<Void, Never>?
    @ObservationIgnored private var filter = SendFilter()

    private(set) var settings: TransmissionSettings {
        didSet { settings.save(to: defaults) }
    }
    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var queueStatus: TelemetryQueue.Status?

    /// The MQTT client identifier, created once and kept.
    private let clientId: String

    init(app: AppModel, defaults: UserDefaults = .standard) {
        self.app = app
        self.defaults = defaults
        settings = TransmissionSettings.load(from: defaults)
        if let id = defaults.string(forKey: "mqttClientId") {
            clientId = id
        } else {
            clientId = UUID().uuidString.lowercased()
            defaults.set(clientId, forKey: "mqttClientId")
        }
        do {
            let folder = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            queue = try TelemetryQueue(url: folder.appending(path: "telemetry.sqlite"))
        } catch {
            fatalError("The offline queue cannot be opened: \(error)")
        }
        link = DeviceLink(queue: queue, handlers: handlers())
        app.deviceChanged = { [weak self] device, isOtherDevice in self?.deviceChanged(device, isOtherDevice: isOtherDevice) }

        if settings.connected { connect() }
        if settings.transmitting { startTicks() }
        refreshQueueStatus()
    }

    // MARK: Controls

    var canConnect: Bool { app.device != nil && Keychain.string(for: .deviceToken) != nil }

    func connect() {
        guard let endpoint else { return }
        settings.connected = true
        callLink { await $0.start(endpoint) }
    }

    func disconnect() {
        settings.connected = false
        callLink { await $0.stop() }
    }

    func setTransmitting(_ on: Bool) {
        guard on != settings.transmitting else { return }
        settings.transmitting = on
        if on { startTicks() } else { stopTicks() }
        publishClientAttributes()
    }

    func setSendRate(_ seconds: Int) {
        guard TransmissionSettings.sendRates.contains(seconds), seconds != settings.sendRate else { return }
        settings.sendRate = seconds
        publishClientAttributes()
    }

    func setSendMode(_ mode: SendMode) {
        settings.sendMode = mode
        filter.mode = mode
    }

    /// The item keys this phone offers.
    var offered: Set<String> { DeviceSampler.offered }

    // MARK: Sampling

    private func startTicks() {
        ticks?.cancel()
        filter = SendFilter(mode: settings.sendMode)
        ticks = Task { [weak self] in
            let clock = ContinuousClock()
            var next = clock.now
            while !Task.isCancelled, let self {
                await self.tick()
                next += .seconds(self.settings.sendRate)
                // After a pause, for example in the background, the ticks start again from now.
                if next < clock.now { next = clock.now + .seconds(self.settings.sendRate) }
                try? await Task.sleep(until: next, clock: clock)
            }
        }
    }

    private func stopTicks() {
        ticks?.cancel()
        ticks = nil
    }

    private func tick() async {
        guard let sample = filter.sample(at: Self.now(), measured: measureSelected()) else { return }
        try? await queue.append(sample)
        refreshQueueStatus()
    }

    /// One sample of all selected values, rounded, for the command `sendNow`.
    private func sendNow() async {
        let values = measureSelected().filter { $0.value.isSendable }.reduce(into: [:]) { result, entry in
            result[entry.key] = SendFilter.round(entry.value, key: entry.key)
        }
        guard !values.isEmpty else { return }
        try? await queue.append(Sample(ts: Self.now(), values: values))
        refreshQueueStatus()
    }

    private func measureSelected() -> [String: TelemetryValue] {
        let keys = Set(settings.selection.items(offered: offered).flatMap(\.sentKeys))
        return sampler.measure().filter { keys.contains($0.key) }
    }

    private static func now() -> Int64 {
        Int64((Date().timeIntervalSince1970 * 1000).rounded())
    }

    // MARK: Device

    private var endpoint: DeviceEndpoint? {
        guard app.device != nil, let token = Keychain.string(for: .deviceToken) else { return nil }
        return DeviceEndpoint(
            host: app.address.host,
            port: ServerAddress.mqttPort,
            accessToken: token,
            clientId: clientId,
            installationId: app.installationId
        )
    }

    /// A device was picked, or the device was forgotten. The samples in the queue belong to the old device.
    private func deviceChanged(_ device: SelectedDevice?, isOtherDevice: Bool) {
        callLink { await $0.stop() }
        if isOtherDevice {
            Task {
                try? await queue.removeAll()
                refreshQueueStatus()
            }
        }
        if device == nil {
            setTransmitting(false)
            settings.connected = false
        } else if settings.connected {
            connect()
        }
    }

    private func callLink(_ call: @escaping (DeviceLink) async -> Void) {
        let previous = linkCalls
        let link = link!
        linkCalls = Task {
            await previous?.value
            await call(link)
        }
    }

    // MARK: Connection

    private func handlers() -> DeviceLinkHandlers {
        DeviceLinkHandlers(
            stateChanged: { [weak self] state in
                Task { @MainActor in self?.connectionStateChanged(state) }
            },
            clientAttributes: { [weak self] in
                await self?.clientAttributes() ?? [:]
            },
            bind: { [weak self] in
                await self?.bind() ?? false
            },
            sharedAttributes: { [weak self] attributes, complete in
                Task { @MainActor in self?.apply(attributes, complete: complete) }
            },
            command: { [weak self] command in
                await self?.carryOut(command) ?? ["error": .string("unknown method")]
            },
            queueChanged: { [weak self] in
                Task { @MainActor in self?.refreshQueueStatus() }
            }
        )
    }

    private func connectionStateChanged(_ state: ConnectionState) {
        connectionState = state
        if case .refused(.boundToAnotherPhone) = state {
            setTransmitting(false)
        }
    }

    private func refreshQueueStatus() {
        Task { queueStatus = try? await queue.status() }
    }

    private func publishClientAttributes() {
        callLink { await $0.publishClientAttributes() }
    }

    /// The client attributes of `docs/spec/messages.md`, Client attributes.
    private func clientAttributes() -> [String: TelemetryValue] {
        let info = Bundle.main.infoDictionary
        return [
            "appVersion": .string(info?["CFBundleShortVersionString"] as? String ?? ""),
            "os": "iOS",
            "osVersion": .string(UIDevice.current.systemVersion),
            "model": .string(DeviceModel.current),
            "sensorsAvailable": .string(Catalog.items.map(\.key).filter(offered.contains).joined(separator: ",")),
            "sensors": .string(settings.selection.reported(offered: offered)),
            "sendRate": .number(Double(settings.sendRate)),
            "transmitting": .bool(settings.transmitting),
        ]
    }

    /// Binds the device to this phone when the binding is missing. Needs a signed-in user.
    private func bind() async -> Bool {
        guard let client = app.client, let device = app.device, await client.isSignedIn else { return false }
        do {
            try await client.setSharedAttributes(deviceId: device.id, [DeviceMessages.bindingKey: .string(app.installationId)])
            return true
        } catch {
            return false
        }
    }

    // MARK: Shared attributes and commands

    /// Applies the settings optiCLOUD manages (see `docs/spec/messages.md`, Changes of shared attributes).
    /// A value the app cannot use is ignored.
    private func apply(_ attributes: [String: JSONValue], complete: Bool) {
        let before = settings
        for key in ["sendRate", "sensors", "dashboard"] {
            switch (key, attributes[key]) {
            case (_, nil):
                if complete { settings.managed.remove(key) }
            case (_, .null?):
                settings.managed.remove(key)
            case ("sendRate", .number(let value)?) where value == value.rounded() && TransmissionSettings.sendRates.contains(Int(value)):
                settings.sendRate = Int(value)
                settings.managed.insert(key)
            case ("sensors", .string(let value)?) where Selection(parsing: value) != nil:
                settings.sensors = value
                settings.managed.insert(key)
            case ("dashboard", .string(let value)?):
                settings.dashboard = value
                settings.managed.insert(key)
            default:
                break
            }
        }
        if settings.sensors != before.sensors { filter.selectionDidChange() }
        if settings.sendRate != before.sendRate || settings.sensors != before.sensors {
            publishClientAttributes()
        }
    }

    /// Carries out a command (see `docs/spec/messages.md`, Commands).
    private func carryOut(_ command: DeviceMessages.Command) async -> [String: JSONValue] {
        switch command.method {
        case "ping":
            return ["pong": .bool(true)]
        case "getState":
            return [
                "transmitting": .bool(settings.transmitting),
                "sendRate": .number(Double(settings.sendRate)),
                "sensors": .string(settings.selection.reported(offered: offered)),
            ]
        case "startTransmission", "stopTransmission":
            let on = command.method == "startTransmission"
            setTransmitting(on)
            return ["transmitting": .bool(on)]
        case "setSendRate":
            guard case .object(let params)? = command.params, case .number(let seconds)? = params["seconds"],
                  seconds == seconds.rounded(), TransmissionSettings.sendRates.contains(Int(seconds))
            else { return ["error": .string("invalid params")] }
            guard !settings.managed.contains("sendRate") else { return ["error": .string("managed setting")] }
            setSendRate(Int(seconds))
            return ["sendRate": .number(seconds)]
        case "sendNow":
            await sendNow()
            return ["sent": .bool(true)]
        default:
            return ["error": .string("unknown method")]
        }
    }
}

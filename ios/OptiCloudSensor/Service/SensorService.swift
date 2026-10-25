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
    /// The location sensor. It also keeps the app running in the background while it is in use.
    let location = LocationSampler()
    private let motion = MotionSampler()
    private let environment = EnvironmentSampler()
    private let activity = ActivitySampler()
    private let sound = SoundSampler()
    /// The app's own data volume.
    let dataVolume: DataVolumeCounter
    @ObservationIgnored private var isInForeground = UIApplication.shared.applicationState != .background
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
    @ObservationIgnored private var queueStatusRefresh: Task<Void, Never>?
    /// The values of the last tick, rounded as they are sent, and the last kind of activity, for the live view.
    private(set) var liveValues: [String: TelemetryValue] = [:]
    private(set) var lastTick: Date?
    /// Since when transmission is on, and how many samples went into the queue since then.
    private(set) var transmittingSince: Date?
    private(set) var samplesSinceStart = 0
    /// The log of the test area.
    let log = TestLog()

    /// The MQTT client identifier, created once and kept.
    private let clientId: String

    init(app: AppModel, dataVolume: DataVolumeCounter = DataVolumeCounter(), defaults: UserDefaults = .standard) {
        self.app = app
        self.dataVolume = dataVolume
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
        activity.activityChanged = { [weak self] type, date in self?.activityChanged(type, at: date) }
        observeForeground()
        updateSensorUse()
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
        updateSensorUse()
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
    let offered: Set<String> = DeviceSampler.offered
        .union(["dataVolume"])
        .union(LocationSampler.offered)
        .union(MotionSampler.offered)
        .union(EnvironmentSampler.offered)
        .union(ActivitySampler.offered)
        .union(SoundSampler.offered)

    /// Changes the selection on the phone. Not possible while optiCLOUD manages it.
    func setSelection(_ selection: Selection) {
        guard !settings.managed.contains("sensors") else { return }
        let text = selection.reported(offered: offered)
        guard text != settings.sensors else { return }
        settings.sensors = text
        selectionChanged()
    }

    // MARK: Test area

    /// Puts a single telemetry value into the offline queue. It is sent as it is, without rounding.
    func sendTestTelemetry(key: String, value: TelemetryValue) async {
        do {
            try await queue.append(Sample(ts: Self.now(), values: [key: value]))
            log.add(.sent, String(localized: "Telemetry \(key)"), detail: value.text)
        } catch {
            log.add(.problem, String(localized: "Telemetry \(key) not queued"), detail: error.localizedDescription)
        }
        refreshQueueStatus()
    }

    /// Publishes a single client attribute. Needs a connection.
    func sendTestAttribute(key: String, value: TelemetryValue) async {
        do {
            try await link.publishClientAttributes([key: value])
            log.add(.sent, String(localized: "Client attribute \(key)"), detail: value.text)
        } catch {
            log.add(.problem, String(localized: "Client attribute \(key) not sent"), detail: String(localized: "Not connected."))
        }
    }

    func resetDiscardedCount() {
        Task {
            try? await queue.resetDiscarded()
            refreshQueueStatus()
        }
    }

    // MARK: Sampling

    private func startTicks() {
        ticks?.cancel()
        filter = SendFilter(mode: settings.sendMode)
        transmittingSince = Date()
        samplesSinceStart = 0
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

    /// A sensor runs while transmission is on and one of its items is selected; its permission is asked for then.
    /// The microphone runs only in the foreground (see `docs/spec/sensors.md`, `sound`).
    private func updateSensorUse() {
        func wanted(_ items: Set<String>) -> Bool {
            settings.transmitting && !settings.selection.items(offered: items).isEmpty
        }
        if wanted(LocationSampler.offered) { location.start() } else { location.stop() }
        if wanted(MotionSampler.offered) { motion.start() } else { motion.stop() }
        if wanted(EnvironmentSampler.offered) { environment.start() } else { environment.stop() }
        if wanted(ActivitySampler.offered) { activity.start() } else { activity.stop() }
        if wanted(SoundSampler.offered) && isInForeground {
            Task { await sound.start() }
        } else {
            sound.stop()
        }
    }

    private func observeForeground() {
        let center = NotificationCenter.default
        Task { [weak self] in
            for await _ in center.notifications(named: UIApplication.didEnterBackgroundNotification) {
                self?.isInForeground = false
                self?.updateSensorUse()
                self?.dataVolume.save()
            }
        }
        Task { [weak self] in
            for await _ in center.notifications(named: UIApplication.willEnterForegroundNotification) {
                self?.isInForeground = true
                self?.updateSensorUse()
            }
        }
    }

    private func selectionChanged() {
        filter.selectionDidChange()
        updateSensorUse()
        publishClientAttributes()
    }

    /// An event value: sent when it arrives, with the time of the measurement (see `docs/spec/sensors.md`, Sampling).
    private func activityChanged(_ type: String, at date: Date) {
        guard settings.transmitting,
              settings.selection.items(offered: offered).contains(where: { $0.key == "activityType" })
        else { return }
        let ts = Int64((date.timeIntervalSince1970 * 1000).rounded())
        liveValues["activityType"] = .string(type)
        Task {
            try? await queue.append(Sample(ts: ts, values: ["activityType": .string(type)]))
            refreshQueueStatus()
        }
    }

    private func stopTicks() {
        ticks?.cancel()
        ticks = nil
        transmittingSince = nil
        liveValues = [:]
        lastTick = nil
    }

    private func tick() async {
        let measured = measureSelected()
        var live = measured.filter { $0.value.isSendable }.reduce(into: [String: TelemetryValue]()) { result, entry in
            result[entry.key] = SendFilter.round(entry.value, key: entry.key)
        }
        live["activityType"] = liveValues["activityType"]
        liveValues = live
        lastTick = Date()
        guard let sample = filter.sample(at: Self.now(), measured: measured) else { return }
        try? await queue.append(sample)
        samplesSinceStart += 1
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
        var values = sampler.measure().merging(dataVolume.telemetry()) { $1 }
        for measured in [location.measure(), motion.measure(), environment.measure(), activity.measure(), sound.measure()] {
            values.merge(measured) { $1 }
        }
        return values.filter { keys.contains($0.key) }
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
            },
            transferred: { [dataVolume] direction, bytes in
                dataVolume.record(direction, bytes)
            }
        )
    }

    private func connectionStateChanged(_ state: ConnectionState) {
        connectionState = state
        switch state {
        case .connected: log.add(.connection, String(localized: "Connected"))
        case .disconnected: log.add(.connection, String(localized: "Disconnected"))
        case .waiting(let problem, _): log.add(.connection, String(localized: "Waiting"), detail: problem.rawValue)
        case .refused(let problem): log.add(.connection, String(localized: "Refused"), detail: problem.rawValue)
        case .connecting: break
        }
        if case .refused(.boundToAnotherPhone) = state {
            setTransmitting(false)
        }
    }

    /// Reads the queue half a second after a change and takes the changes of that half second together. A sample
    /// is delivered a few milliseconds after it was queued; showing it in between made the numbers flicker.
    private func refreshQueueStatus() {
        guard queueStatusRefresh == nil else { return }
        queueStatusRefresh = Task {
            try? await Task.sleep(for: .milliseconds(500))
            let status = try? await queue.status()
            if status != queueStatus { queueStatus = status }
            queueStatusRefresh = nil
        }
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
        log.add(
            .sharedAttribute,
            complete ? String(localized: "Shared attributes after connect") : String(localized: "Shared attributes changed"),
            detail: JSONValue.object(attributes).jsonText
        )
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
                log.add(.problem, String(localized: "Ignored \(key)"), detail: String(localized: "The value \(attributes[key]?.jsonText ?? "") cannot be used."))
            }
        }
        if settings.sensors != before.sensors {
            selectionChanged()
        } else if settings.sendRate != before.sendRate {
            publishClientAttributes()
        }
    }

    /// Carries out a command and shows it with its answer in the test area.
    private func carryOut(_ command: DeviceMessages.Command) async -> [String: JSONValue] {
        let answer = await answer(command)
        log.add(
            .command,
            String(localized: "Command \(command.method)"),
            detail: String(localized: "Params: \(command.params?.jsonText ?? "none")\nAnswer: \(JSONValue.object(answer).jsonText)")
        )
        return answer
    }

    /// The effect and the answer of a command (see `docs/spec/messages.md`, Commands).
    private func answer(_ command: DeviceMessages.Command) async -> [String: JSONValue] {
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

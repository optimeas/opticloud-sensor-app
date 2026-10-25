import Foundation
import Logging
import MQTTNIO
import Network
import NIOCore
import NIOTransportServices
import SensorCore

/// Where and as which device the app connects (see `docs/spec/connection.md`).
public struct DeviceEndpoint: Hashable, Sendable {
    public var host: String
    public var port: Int
    public var accessToken: String
    /// The MQTT client identifier: a random UUID the app creates once and keeps.
    public var clientId: String
    /// The installation identifier the binding is checked against. Nil in the support mode, which does not check it.
    public var installationId: String?

    public init(host: String, port: Int, accessToken: String, clientId: String, installationId: String?) {
        self.host = host
        self.port = port
        self.accessToken = accessToken
        self.clientId = clientId
        self.installationId = installationId
    }
}

/// What the connection asks of the app and tells it. The closures are called on the connection's own executor.
public struct DeviceLinkHandlers: Sendable {
    public var stateChanged: @Sendable (ConnectionState) -> Void
    /// The client attributes to publish after every connect.
    public var clientAttributes: @Sendable () async -> [String: TelemetryValue]
    /// Binds the device to this phone through the REST interface. Returns false if nobody is signed in or it failed.
    public var bind: @Sendable () async -> Bool
    /// Shared attributes. With `complete` they are the answer after a connect, and a missing key does not exist.
    /// Otherwise they are a change, and `null` means deleted.
    public var sharedAttributes: @Sendable (_ attributes: [String: JSONValue], _ complete: Bool) -> Void
    /// Carries out a command and returns the answer.
    public var command: @Sendable (DeviceMessages.Command) async -> [String: JSONValue]
    /// The offline queue changed: a message was delivered or discarded.
    public var queueChanged: @Sendable () -> Void

    public init(
        stateChanged: @escaping @Sendable (ConnectionState) -> Void,
        clientAttributes: @escaping @Sendable () async -> [String: TelemetryValue],
        bind: @escaping @Sendable () async -> Bool,
        sharedAttributes: @escaping @Sendable (_ attributes: [String: JSONValue], _ complete: Bool) -> Void,
        command: @escaping @Sendable (DeviceMessages.Command) async -> [String: JSONValue],
        queueChanged: @escaping @Sendable () -> Void
    ) {
        self.stateChanged = stateChanged
        self.clientAttributes = clientAttributes
        self.bind = bind
        self.sharedAttributes = sharedAttributes
        self.command = command
        self.queueChanged = queueChanged
    }
}

/// The MQTT connection of the device: signing on, subscriptions, the binding check, delivery of the offline queue,
/// commands, and reconnecting (see `docs/spec/connection.md` and `docs/spec/messages.md`).
public actor DeviceLink {
    /// No answer to an attribute request within this time means the request failed.
    static let responseTimeout: Duration = .seconds(10)
    /// After this many closed connections without an acknowledgment, a message is assumed unreadable.
    static let strikesBeforeDiscard = 3

    private let queue: TelemetryQueue
    private let handlers: DeviceLinkHandlers
    private let logger = Logger(label: "DeviceLink", factory: { _ in SwiftLogNoOpLogHandler() })

    private(set) var state: ConnectionState = .disconnected
    private var runTask: Task<Void, Never>?
    private var connection: MQTTConnection?
    private var isConnected = false
    private var requestId = 0
    private var responses: [Int: Response] = [:]
    private var inFlight: TelemetryQueue.Message?
    private var strike: (firstRow: Int64, count: Int)?

    private let pathMonitor = NWPathMonitor()
    private var networkAvailable = true
    private var retryWaiter: CheckedContinuation<Void, Never>?

    private enum Response {
        case waiting(CheckedContinuation<Data?, Never>?)
        case arrived(Data)
    }

    /// Ends an attempt. `refused` stops retrying; everything else leads to Waiting.
    private enum Failure: Error {
        case refused(ConnectionProblem)
        case noAnswer
    }

    public init(queue: TelemetryQueue, handlers: DeviceLinkHandlers) {
        self.queue = queue
        self.handlers = handlers
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { await self?.networkChanged(path.status == .satisfied) }
        }
        pathMonitor.start(queue: DispatchQueue(label: "DeviceLink.path"))
    }

    deinit {
        pathMonitor.cancel()
        runTask?.cancel()
    }

    // MARK: Control

    /// Connects, and keeps connecting after a loss, until `stop()`. A running connection is replaced.
    public func start(_ endpoint: DeviceEndpoint) async {
        await stop()
        set(.connecting)
        runTask = Task { await self.run(endpoint) }
    }

    /// Disconnects, sending DISCONNECT if a connection exists, and goes to Disconnected.
    public func stop() async {
        guard let task = runTask else { return }
        runTask = nil
        task.cancel()
        wakeRetry()
        await task.value
        set(.disconnected)
    }

    /// Publishes the client attributes again, when one of them changed. Does nothing while not connected.
    public func publishClientAttributes() async {
        guard isConnected, let connection else { return }
        try? await publishClientAttributes(on: connection)
    }

    // MARK: Connecting

    private func run(_ endpoint: DeviceEndpoint) async {
        var backoff = Backoff()
        while !Task.isCancelled {
            set(.connecting)
            let problem: ConnectionProblem
            do {
                try await connect(endpoint)
                problem = .connectionLost
            } catch Failure.refused(let reason) {
                await endConnection(acknowledged: false)
                if !Task.isCancelled { set(.refused(reason)) }
                return
            } catch {
                problem = classify(error)
            }
            let wasConnected = isConnected
            await endConnection(acknowledged: false)
            if Task.isCancelled { return }
            if wasConnected { backoff.reset() }

            let delay = backoff.nextDelay()
            set(.waiting(problem, retryAt: Date(timeIntervalSinceNow: delay)))
            await waitForRetry(seconds: delay)
        }
    }

    private func connect(_ endpoint: DeviceEndpoint) async throws {
        let configuration = MQTTConnectionConfiguration(
            versionConfiguration: .v3_1_1(),
            keepAliveInterval: .seconds(60),
            pingConfiguration: .useServerKeepAlive,
            connectTimeout: .seconds(20),
            // Also the time the app waits for a PINGRESP before it treats the connection as lost.
            timeout: .seconds(20),
            userName: endpoint.accessToken,
            transport: .tcp(tls: .enable(.ts(TSTLSConfiguration()), tlsServerName: endpoint.host))
        )
        try await MQTTConnection.withConnection(
            address: .hostname(endpoint.host, port: endpoint.port),
            configuration: configuration,
            identifier: endpoint.clientId,
            eventLoop: NIOTSEventLoopGroup.singleton.any(),
            logger: logger
        ) { connection in
            self.connection = connection
            requestId = 0
            let filters = DeviceMessages.subscriptions.map { MQTTSubscribeInfo(topicFilter: $0, qos: .atLeastOnce) }
            try await connection.subscribe(to: filters) { subscription in
                try await withThrowingTaskGroup { group in
                    group.addTask {
                        for try await message in subscription {
                            try await self.receive(message, on: connection, endpoint: endpoint)
                        }
                        throw MQTTError.connectionClosed
                    }
                    group.addTask {
                        try await self.signOn(connection, endpoint: endpoint)
                        try await self.deliver(on: connection)
                    }
                    // Either task ends only with an error or by cancellation; the other one follows.
                    try await group.next()
                    group.cancelAll()
                }
            }
        }
    }

    /// Checks the binding and publishes the client attributes (see `docs/spec/connection.md`, Checking the binding).
    private func signOn(_ connection: MQTTConnection, endpoint: DeviceEndpoint) async throws {
        guard let shared = try await requestSharedAttributes(on: connection) else { throw Failure.noAnswer }
        if let installationId = endpoint.installationId {
            switch BindingCheck(sharedAttributes: shared, installationId: installationId) {
            case .same:
                break
            case .other:
                throw Failure.refused(.boundToAnotherPhone)
            case .missing:
                guard await handlers.bind() else { throw Failure.refused(.notBound) }
            }
        }
        isConnected = true
        set(.connected)
        handlers.sharedAttributes(shared, true)
        try await publishClientAttributes(on: connection)
    }

    private func publishClientAttributes(on connection: MQTTConnection) async throws {
        let payload = try DeviceMessages.clientAttributes(await handlers.clientAttributes())
        try await connection.publish(to: DeviceMessages.attributesTopic, payload: ByteBuffer(data: payload), qos: .atLeastOnce)
    }

    // MARK: Receiving

    private func receive(_ message: MQTTPublishInfo, on connection: MQTTConnection, endpoint: DeviceEndpoint) async throws {
        let payload = Data(buffer: message.payload)
        let topic = message.topicName
        if topic == DeviceMessages.attributesTopic {
            guard let changes = try? DeviceMessages.sharedAttributes(from: payload) else { return }
            if let installationId = endpoint.installationId, changes[DeviceMessages.bindingKey] != nil,
               BindingCheck(sharedAttributes: changes, installationId: installationId) == .other
            {
                throw Failure.refused(.boundToAnotherPhone)
            }
            handlers.sharedAttributes(changes, false)
        } else if let id = DeviceMessages.requestId(topic: topic, prefix: DeviceMessages.attributeResponsePrefix) {
            resolve(id, with: payload)
        } else if let id = DeviceMessages.requestId(topic: topic, prefix: DeviceMessages.rpcRequestPrefix) {
            let answer: [String: JSONValue]
            if let command = DeviceMessages.command(topic: topic, payload: payload) {
                answer = await handlers.command(command)
            } else {
                answer = ["error": .string("unknown method")]
            }
            try await connection.publish(
                to: DeviceMessages.commandResponseTopic(id: id),
                payload: ByteBuffer(data: DeviceMessages.commandResponse(answer)),
                qos: .atLeastOnce
            )
        }
    }

    /// Requests the shared attributes the app uses. Returns nil if no answer arrives in time.
    private func requestSharedAttributes(on connection: MQTTConnection) async throws -> [String: JSONValue]? {
        requestId += 1
        let id = requestId
        responses[id] = .waiting(nil)
        try await connection.publish(
            to: DeviceMessages.attributeRequestPrefix + String(id),
            payload: ByteBuffer(data: DeviceMessages.attributeRequest(sharedKeys: DeviceMessages.requestedSharedKeys)),
            qos: .atLeastOnce
        )
        let timeout = Task {
            try? await Task.sleep(for: Self.responseTimeout)
            self.resolve(id, with: nil)
        }
        defer { timeout.cancel() }
        let payload: Data? = await withCheckedContinuation { continuation in
            if case .arrived(let data)? = responses[id] {
                responses[id] = nil
                continuation.resume(returning: data)
            } else {
                responses[id] = .waiting(continuation)
            }
        }
        return try payload.map { try DeviceMessages.sharedAttributes(from: $0) }
    }

    private func resolve(_ id: Int, with payload: Data?) {
        switch responses[id] {
        case .waiting(let continuation?):
            responses[id] = nil
            continuation.resume(returning: payload)
        case .waiting(nil):
            if let payload { responses[id] = .arrived(payload) }
        case .arrived, nil:
            break
        }
    }

    // MARK: Delivering

    /// Delivers the offline queue, one message at a time, for as long as the connection lasts
    /// (see `docs/spec/offline-queue.md`, Delivering).
    private func deliver(on connection: MQTTConnection) async throws {
        let additions = await queue.additions()
        var signals = additions.makeAsyncIterator()
        while !Task.isCancelled {
            while let message = try await queue.nextMessage() {
                inFlight = message
                try await connection.publish(to: Telemetry.topic, payload: ByteBuffer(data: message.payload), qos: .atLeastOnce)
                inFlight = nil
                strike = nil
                try await queue.remove(message)
                handlers.queueChanged()
            }
            guard await signals.next() != nil else { return }
        }
    }

    /// Cleans up after a connection. A message that was not acknowledged counts as a strike against it.
    private func endConnection(acknowledged: Bool) async {
        connection = nil
        isConnected = false
        for (id, _) in responses { resolve(id, with: nil) }
        responses = [:]
        guard let message = inFlight else { return }
        inFlight = nil
        let count = strike?.firstRow == message.firstRow ? strike!.count + 1 : 1
        strike = (message.firstRow, count)
        if count >= Self.strikesBeforeDiscard {
            strike = nil
            try? await queue.discard(message)
            handlers.queueChanged()
        }
    }

    // MARK: Waiting

    private func waitForRetry(seconds: Double) async {
        let timer = Task {
            try? await Task.sleep(for: .seconds(seconds))
            self.wakeRetry()
        }
        defer { timer.cancel() }
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume()
                } else {
                    retryWaiter = continuation
                }
            }
        } onCancel: {
            Task { await self.wakeRetry() }
        }
    }

    private func wakeRetry() {
        retryWaiter?.resume()
        retryWaiter = nil
    }

    /// When the network comes back, the app retries at once.
    private func networkChanged(_ available: Bool) {
        let cameBack = available && !networkAvailable
        networkAvailable = available
        if cameBack { wakeRetry() }
    }

    private func classify(_ error: any Error) -> ConnectionProblem {
        if !networkAvailable { return .noNetwork }
        if isConnected { return .connectionLost }
        switch error {
        case MQTTError.connectionError(.badUserNameOrPassword), MQTTError.connectionError(.notAuthorized):
            return .tokenRefused
        case let error as NWError:
            if case .tls = error { return .certificateNotTrusted }
            return .serverNotReachable
        default:
            return .serverNotReachable
        }
    }

    private func set(_ newState: ConnectionState) {
        guard newState != state else { return }
        state = newState
        handlers.stateChanged(newState)
    }
}

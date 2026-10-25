package com.optimeas.opticloudsensor.core.connection

import com.optimeas.opticloudsensor.core.Catalog
import com.optimeas.opticloudsensor.core.JsonCodec
import com.optimeas.opticloudsensor.core.Sample
import com.optimeas.opticloudsensor.core.SendFilter
import com.optimeas.opticloudsensor.core.SendMode
import com.optimeas.opticloudsensor.core.Telemetry
import com.optimeas.opticloudsensor.core.TelemetryValue
import com.optimeas.opticloudsensor.core.api.BINDING_ATTRIBUTE
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.isActive
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** Keeps the settings of transmission across a restart of the app. */
interface SettingsStore {
    fun load(): DeviceSettings

    fun save(settings: DeviceSettings)
}

/** The sensors of the phone (see `docs/spec/sensors.md`). */
interface SensorSource {
    /** The keys of the items this phone offers. */
    val offered: Set<String>

    /** Measures the given items now. Values that are not available are missing. */
    fun measure(items: List<String>): Map<String, TelemetryValue>
}

/** What happens to the binding check (see `docs/spec/connection.md`, Checking the binding). */
fun interface Binder {
    /** Binds the device to this phone through the REST interface. Returns false if no user is signed in or it failed. */
    suspend fun bind(): Boolean
}

/** An entry of the log the test area shows. */
data class LogEntry(val ts: Long, val kind: Kind, val text: String, val detail: String? = null) {
    enum class Kind { STATE, SHARED_ATTRIBUTES, COMMAND, PROBLEM }
}

/**
 * The service layer of the connection (see `docs/spec/connection.md`): it connects as the device, keeps the
 * connection alive and reconnects, applies shared attributes and commands, samples the selected sensors while
 * transmission is on, and delivers the offline queue. It does not depend on the user interface.
 */
class ConnectionService(
    private val scope: CoroutineScope,
    private val connector: MqttConnector,
    private val queue: TelemetryQueue,
    private val settingsStore: SettingsStore,
    private val source: SensorSource,
    private val binder: Binder,
    private val installationId: String,
    /** The endpoint of the chosen device, or null if no device is chosen. */
    private val endpoint: () -> MqttEndpoint?,
    /** Whether the operating system reports a network. */
    private val network: StateFlow<Boolean>,
    /** Client attributes of the app and the phone, such as `appVersion` and `model`. */
    private val staticAttributes: Map<String, TelemetryValue>,
    private val clock: () -> Long = System::currentTimeMillis,
    private val random: () -> Double = Math::random,
) {
    private val _state = MutableStateFlow<ConnectionState>(ConnectionState.Disconnected)
    val state: StateFlow<ConnectionState> = _state.asStateFlow()

    private val _settings = MutableStateFlow(settingsStore.load())
    val settings: StateFlow<DeviceSettings> = _settings.asStateFlow()

    private val _log = MutableStateFlow<List<LogEntry>>(emptyList())
    val log: StateFlow<List<LogEntry>> = _log.asStateFlow()

    private val settingsLock = Any()
    private val control = Mutex()
    private var connection: Job? = null
    private val sendNow = Channel<Unit>(Channel.CONFLATED)

    /** Starts the service: connects if the user wished so before, and samples while transmission is on. */
    fun start() {
        scope.launch { transmit() }
        if (settings.value.connected) scope.launch { control.withLock { restartConnection() } }
    }

    /** The user connects: Disconnected or Refused → Connecting. */
    fun connect() {
        changeSettings { it.copy(connected = true) }
        scope.launch {
            control.withLock {
                if (connection?.isActive != true) restartConnection()
            }
        }
    }

    /** The user disconnects: any state → Disconnected. */
    fun disconnect() {
        changeSettings { it.copy(connected = false) }
        scope.launch { control.withLock { stopConnection() } }
    }

    /** The device or its token changed. A running connection starts again with the new device. */
    fun deviceChanged() {
        scope.launch {
            control.withLock {
                stopConnection()
                if (settings.value.connected) restartConnection()
            }
        }
    }

    fun setTransmitting(on: Boolean) = changeSettings { it.copy(transmitting = on) }

    /** Changes a setting of the user. Returns false if optiCLOUD manages it. */
    fun setSendRate(seconds: Int): Boolean = changeUnmanaged("sendRate") { it.copy(sendRate = seconds) }

    fun setSensors(sensors: String): Boolean = changeUnmanaged("sensors") { it.copy(sensors = sensors) }

    fun setDashboard(dashboard: String?): Boolean = changeUnmanaged("dashboard") { it.copy(dashboard = dashboard) }

    fun setSendMode(mode: SendMode) = changeSettings { it.copy(sendMode = mode) }

    /** The selection as the app reports it, for example `device,location`. */
    fun reportedSensors(settings: DeviceSettings = this.settings.value): String =
        settings.selection.report(source.offered).joinToString(",")

    private fun changeUnmanaged(key: String, change: (DeviceSettings) -> DeviceSettings): Boolean {
        require(key in DeviceSettings.MANAGED_KEYS)
        var changed = false
        changeSettings {
            if (key in it.managed) {
                it
            } else {
                changed = true
                change(it)
            }
        }
        return changed
    }

    private fun changeSettings(change: (DeviceSettings) -> DeviceSettings) {
        synchronized(settingsLock) {
            val old = _settings.value
            val new = change(old)
            if (new != old) {
                _settings.value = new
                settingsStore.save(new)
            }
        }
    }

    private fun addLog(kind: LogEntry.Kind, text: String, detail: String? = null) {
        _log.update { (it + LogEntry(clock(), kind, text, detail)).takeLast(LOG_SIZE) }
    }

    private fun setState(state: ConnectionState) {
        _state.value = state
        val text = when (state) {
            is ConnectionState.Waiting -> "Waiting: ${state.reason}"
            is ConnectionState.Refused -> "Refused: ${state.reason}"
            else -> state.toString()
        }
        addLog(LogEntry.Kind.STATE, text)
    }

    // Connection

    private suspend fun restartConnection() {
        stopConnection()
        connection = scope.launch { connectLoop() }
    }

    private suspend fun stopConnection() {
        connection?.cancelAndJoin()
        connection = null
        if (_state.value != ConnectionState.Disconnected) setState(ConnectionState.Disconnected)
    }

    /** Connects and reconnects until the user disconnects or the server refuses (see Reconnecting). */
    private suspend fun connectLoop() {
        var failures = 0
        while (true) {
            if (!network.value) {
                setState(ConnectionState.Waiting(ConnectionReason.NO_NETWORK, clock(), null))
                network.first { it }
            }
            val endpoint = endpoint() ?: run {
                setState(ConnectionState.Disconnected)
                return
            }
            setState(ConnectionState.Connecting)
            val ended = runSession(endpoint, onConnected = { failures = 0 })
            if (ended is Ending.Refused) {
                setState(ConnectionState.Refused(ended.reason, clock()))
                return
            }
            ended as Ending.Lost
            failures++
            val now = clock()
            val delayMillis = ReconnectDelay.millis(failures, random())
            val reason = if (network.value) ended.reason else ConnectionReason.NO_NETWORK
            setState(ConnectionState.Waiting(reason, now, now + delayMillis))
            // When the network goes away during the delay, the loop waits for it to come back and retries at once.
            withTimeoutOrNull(delayMillis) { network.first { !it } }
        }
    }

    private sealed interface Ending {
        data class Lost(val reason: ConnectionReason) : Ending

        data class Refused(val reason: ConnectionReason) : Ending
    }

    private class EndSession(val ending: Ending) : Exception()

    private var inFlight: QueueMessage? = null

    private suspend fun runSession(endpoint: MqttEndpoint, onConnected: () -> Unit): Ending {
        // Messages of an earlier connection must not be answered on this one.
        while (incoming.tryReceive().isSuccess) Unit
        val session = try {
            connector.connect(endpoint, ::onMessage)
        } catch (e: MqttFailure) {
            return ending(e)
        }
        return try {
            coroutineScope {
                session.subscribe(DeviceMessages.SUBSCRIPTIONS)
                requestCounter = 0
                val shared = requestSharedAttributes(session) ?: throw EndSession(Ending.Lost(ConnectionReason.CONNECTION_LOST))
                applyShared(shared, complete = true)
                checkBinding(shared[BINDING_ATTRIBUTE])
                onConnected()
                setState(ConnectionState.Connected)
                launch { handleIncoming(session) }
                launch { publishClientAttributes(session) }
                launch { deliver(session) }
                throw session.awaitClosed()
            }
        } catch (e: EndSession) {
            e.ending
        } catch (e: MqttFailure) {
            ending(e)
        } finally {
            inFlight?.let { message ->
                inFlight = null
                // Only a connection the server closed counts against the message, not one the user ended.
                if (currentCoroutineIsActive()) queue.connectionClosed(message)
            }
            withContext(NonCancellable) { runCatching { session.disconnect() } }
            pendingRequests.values.forEach { it.cancel() }
            pendingRequests.clear()
        }
    }

    private suspend fun currentCoroutineIsActive() = currentCoroutineContext().isActive

    private fun ending(failure: MqttFailure): Ending = when (failure.kind) {
        MqttFailure.Kind.BAD_CREDENTIALS, MqttFailure.Kind.NOT_AUTHORIZED -> Ending.Refused(ConnectionReason.TOKEN_REFUSED)
        MqttFailure.Kind.SERVER_UNAVAILABLE, MqttFailure.Kind.UNREACHABLE -> Ending.Lost(ConnectionReason.SERVER_NOT_REACHABLE)
        MqttFailure.Kind.CERTIFICATE -> Ending.Lost(ConnectionReason.CERTIFICATE_NOT_TRUSTED)
        MqttFailure.Kind.SUBSCRIPTION_REFUSED, MqttFailure.Kind.LOST -> Ending.Lost(ConnectionReason.CONNECTION_LOST)
    }

    /** Compares the binding with this phone; ends the session if the device belongs to another phone. */
    private suspend fun checkBinding(binding: JsonElement?) {
        val value = (binding as? JsonPrimitive)?.takeIf { it.isString }?.content
        when {
            value == installationId -> Unit
            value != null -> refuseBinding()
            binder.bind() -> addLog(LogEntry.Kind.STATE, "Bound the device to this phone")
            else -> throw EndSession(Ending.Refused(ConnectionReason.NOT_BOUND))
        }
    }

    private fun refuseBinding(): Nothing {
        setTransmitting(false)
        throw EndSession(Ending.Refused(ConnectionReason.BOUND_TO_ANOTHER_PHONE))
    }

    // Incoming messages

    private val incoming = Channel<Pair<String, String>>(Channel.UNLIMITED)
    private val pendingRequests = java.util.concurrent.ConcurrentHashMap<Long, CompletableDeferred<Map<String, JsonElement>>>()
    private var requestCounter = 0L

    private fun onMessage(topic: String, payload: String) {
        val id = DeviceMessages.requestId(topic, DeviceMessages.ATTRIBUTE_RESPONSE_PREFIX)
        if (id != null) {
            val shared = DeviceMessages.sharedAttributes(payload)
            if (shared == null) {
                addLog(LogEntry.Kind.PROBLEM, "Unreadable attribute response", payload.take(200))
            } else {
                pendingRequests.remove(id)?.complete(shared)
            }
        } else {
            incoming.trySend(topic to payload)
        }
    }

    /** Requests the shared attributes the app uses. Null if no answer arrives in time. */
    private suspend fun requestSharedAttributes(session: MqttSession): Map<String, JsonElement>? {
        val id = ++requestCounter
        val answer = CompletableDeferred<Map<String, JsonElement>>()
        pendingRequests[id] = answer
        session.publish(DeviceMessages.ATTRIBUTE_REQUEST_PREFIX + id, DeviceMessages.attributeRequest(DeviceMessages.REQUESTED_SHARED_KEYS))
        return withTimeoutOrNull(DeviceMessages.REQUEST_TIMEOUT_MILLIS) { answer.await() }.also { pendingRequests.remove(id) }
    }

    private suspend fun handleIncoming(session: MqttSession) = coroutineScope {
        for ((topic, payload) in incoming) {
            if (topic == DeviceMessages.ATTRIBUTES) {
                val shared = DeviceMessages.sharedAttributes(payload)
                if (shared == null) {
                    addLog(LogEntry.Kind.PROBLEM, "Unreadable change of shared attributes", payload.take(200))
                    continue
                }
                applyShared(shared, complete = false)
                val binding = shared[BINDING_ATTRIBUTE]
                if (binding != null && binding != JsonNull && binding != JsonPrimitive(installationId)) refuseBinding()
                continue
            }
            val id = DeviceMessages.requestId(topic, DeviceMessages.RPC_REQUEST_PREFIX) ?: continue
            val command = DeviceMessages.command(payload)
            val answer = if (command == null) {
                addLog(LogEntry.Kind.COMMAND, "Unreadable command", payload.take(200))
                JsonObject(mapOf("error" to JsonPrimitive(Commands.INVALID_PARAMS)))
            } else {
                carryOut(command)
            }
            launch { session.publish(DeviceMessages.RPC_RESPONSE_PREFIX + id, JsonCodec.compact(answer)) }
        }
    }

    private fun applyShared(shared: Map<String, JsonElement>, complete: Boolean) {
        addLog(
            LogEntry.Kind.SHARED_ATTRIBUTES,
            if (complete) "Shared attributes after connect" else "Shared attributes changed",
            JsonCodec.compact(JsonObject(shared)),
        )
        var ignored: Map<String, JsonElement> = emptyMap()
        changeSettings { current ->
            SharedAttributes.apply(current, shared, complete).also { ignored = it.ignored }.settings
        }
        for ((key, value) in ignored) addLog(LogEntry.Kind.PROBLEM, "Ignored $key", "The value $value cannot be used.")
    }

    private fun carryOut(command: DeviceMessages.Command): JsonObject {
        var result: CommandResult? = null
        changeSettings { current ->
            Commands.carryOut(command, current, reportedSensors(current)).also { result = it }.settings
        }
        val done = result!!
        if (done.sendNow) sendNow.trySend(Unit)
        addLog(LogEntry.Kind.COMMAND, command.method, "${JsonCodec.compact(command.params)} → ${JsonCodec.compact(done.answer)}")
        return done.answer
    }

    // Outgoing messages

    /** Publishes the client attributes after the connect and again whenever one of them changes. */
    private suspend fun publishClientAttributes(session: MqttSession) {
        settings.map(::clientAttributes).distinctUntilChanged().collect { attributes ->
            session.publish(DeviceMessages.ATTRIBUTES, DeviceMessages.clientAttributes(attributes))
        }
    }

    private fun clientAttributes(settings: DeviceSettings): Map<String, TelemetryValue> = staticAttributes + mapOf(
        "sensorsAvailable" to TelemetryValue.Text(Catalog.items.map { it.key }.filter { it in source.offered }.joinToString(",")),
        "sensors" to TelemetryValue.Text(reportedSensors(settings)),
        "sendRate" to TelemetryValue.Number(settings.sendRate.toDouble()),
        "transmitting" to TelemetryValue.Bool(settings.transmitting),
    )

    /** Delivers the queue, one unacknowledged message at a time (see `docs/spec/offline-queue.md`, Delivering). */
    private suspend fun deliver(session: MqttSession) {
        while (true) {
            val message = queue.next()
            if (message == null) {
                queue.status.first { it.count > 0 }
                continue
            }
            inFlight = message
            session.publish(Telemetry.TOPIC, message.payload)
            inFlight = null
            queue.acknowledged(message)
        }
    }

    // Transmission

    /** Samples the selected sensors at the send rate while transmission is on, and on the command `sendNow`. */
    private suspend fun transmit() = coroutineScope {
        launch {
            for (unused in sendNow) sampleAll()
        }
        var filter = SendFilter()
        var lastSensors: String? = null
        settings.map { Triple(it.transmitting, it.sendRate, it.sendMode) }.distinctUntilChanged().collectLatest { (on, rate, mode) ->
            if (!on) {
                lastSensors = null
                return@collectLatest
            }
            if (lastSensors == null) filter = SendFilter(mode)
            filter.mode = mode
            var next = clock()
            while (true) {
                val current = settings.value
                if (lastSensors != null && current.sensors != lastSensors) filter.selectionChanged()
                lastSensors = current.sensors
                val ts = clock()
                val measured = source.measure(current.selection.items(source.offered))
                filter.sample(ts, measured)?.let(queue::append)
                next += rate * 1000L
                delay((next - clock()).coerceAtLeast(0))
            }
        }
    }

    /** One sample of all selected values at once, also while transmission is off. */
    private fun sampleAll() {
        val current = settings.value
        val measured = source.measure(current.selection.items(source.offered))
        val values = measured.filterValues { it.isSendable }.mapValues { (key, value) -> SendFilter.round(value, key) }
        if (values.isNotEmpty()) queue.append(Sample(clock(), values))
    }

    private companion object {
        const val LOG_SIZE = 200
    }
}

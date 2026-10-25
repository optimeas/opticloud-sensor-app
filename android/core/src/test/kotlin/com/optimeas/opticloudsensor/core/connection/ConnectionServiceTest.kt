package com.optimeas.opticloudsensor.core.connection

import com.optimeas.opticloudsensor.core.TelemetryValue
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

private const val INSTALLATION = "11111111-2222-3333-4444-555555555555"

/** A broker that answers the attribute request with [shared] and records what the app publishes. */
private class FakeBroker(var shared: String = """{"shared":{"sensorAppInstallation":"$INSTALLATION"}}""") : MqttConnector {
    val published = mutableListOf<Pair<String, String>>()
    val subscribed = mutableListOf<String>()
    var attempts = 0
    var failWith: MqttFailure.Kind? = null
    var acknowledge = true
    var session: Session? = null

    inner class Session(val onMessage: (String, String) -> Unit) : MqttSession {
        val closed = CompletableDeferred<MqttFailure>()
        var disconnected = false

        override suspend fun subscribe(filters: List<String>) {
            subscribed += filters
        }

        override suspend fun publish(topic: String, payload: String) {
            if (closed.isCompleted) throw closed.await()
            published += topic to payload
            if (topic.startsWith(DeviceMessages.ATTRIBUTE_REQUEST_PREFIX)) {
                onMessage(DeviceMessages.ATTRIBUTE_RESPONSE_PREFIX + topic.substringAfterLast('/'), shared)
            }
            if (!acknowledge && topic == "v2/json/devices/me/telemetry") throw closed.await()
        }

        override suspend fun awaitClosed() = closed.await()

        override suspend fun disconnect() {
            disconnected = true
        }

        fun lose() = closed.complete(MqttFailure(MqttFailure.Kind.LOST))
    }

    override suspend fun connect(endpoint: MqttEndpoint, onMessage: (String, String) -> Unit): MqttSession {
        attempts++
        failWith?.let { throw MqttFailure(it) }
        return Session(onMessage).also { session = it }
    }

    fun topics() = published.map { it.first }
}

private class Store(var value: DeviceSettings = DeviceSettings()) : SettingsStore {
    override fun load() = value

    override fun save(settings: DeviceSettings) {
        value = settings
    }
}

private object Battery : SensorSource {
    override val offered = setOf("batteryLevel", "charging")

    var level = 0.5

    override fun measure(items: List<String>) = buildMap<String, TelemetryValue> {
        if ("batteryLevel" in items) put("batteryLevel", TelemetryValue.Number(level))
        if ("charging" in items) put("charging", TelemetryValue.Bool(false))
    }
}

@OptIn(ExperimentalCoroutinesApi::class)
class ConnectionServiceTest {
    private val network = MutableStateFlow(true)
    private val queue = TelemetryQueue(MemoryQueueStore())
    private var bindCalls = 0
    private var canBind = true

    private fun TestScope.service(broker: FakeBroker, store: Store = Store()) = ConnectionService(
        scope = backgroundScope,
        connector = broker,
        queue = queue,
        settingsStore = store,
        source = Battery,
        binder = { bindCalls++; canBind },
        installationId = INSTALLATION,
        endpoint = { MqttEndpoint("example.com", 8883, "client", "token") },
        network = network,
        staticAttributes = mapOf("os" to TelemetryValue.Text("Android")),
        clock = { testScheduler.currentTime },
        random = { 0.5 },
    ).also { it.start() }

    @Test
    fun connectsSubscribesChecksTheBindingAndPublishesClientAttributes() = runTest {
        val broker = FakeBroker()
        val service = service(broker)
        service.connect()
        runCurrent()
        assertEquals(ConnectionState.Connected, service.state.value)
        assertEquals(DeviceMessages.SUBSCRIPTIONS, broker.subscribed)
        assertEquals(
            "v2/json/devices/me/attributes/request/1" to """{"sharedKeys":"sendRate,sensors,dashboard,sensorAppInstallation"}""",
            broker.published[0],
        )
        assertEquals(
            "v2/json/devices/me/attributes" to
                """{"os":"Android","sensorsAvailable":"batteryLevel,charging","sensors":"device","sendRate":2,"transmitting":false}""",
            broker.published[1],
        )
        assertTrue(service.settings.value.connected)
    }

    @Test
    fun anotherPhoneRefusesAndSwitchesTransmissionOff() = runTest {
        val broker = FakeBroker("""{"shared":{"sensorAppInstallation":"other"}}""")
        val service = service(broker, Store(DeviceSettings(transmitting = true)))
        service.connect()
        runCurrent()
        assertEquals(ConnectionReason.BOUND_TO_ANOTHER_PHONE, (service.state.value as ConnectionState.Refused).reason)
        assertFalse(service.settings.value.transmitting)
        assertTrue(broker.session!!.disconnected)
        advanceTimeBy(120_000)
        assertEquals(1, broker.attempts)
    }

    @Test
    fun aMissingBindingIsWrittenWhenSignedIn() = runTest {
        val broker = FakeBroker("""{"shared":{}}""")
        val service = service(broker)
        service.connect()
        runCurrent()
        assertEquals(1, bindCalls)
        assertEquals(ConnectionState.Connected, service.state.value)
    }

    @Test
    fun aMissingBindingWithoutSignInRefuses() = runTest {
        canBind = false
        val service = service(FakeBroker("""{}"""))
        service.connect()
        runCurrent()
        assertEquals(ConnectionReason.NOT_BOUND, (service.state.value as ConnectionState.Refused).reason)
    }

    @Test
    fun aLaterChangeOfTheBindingRefuses() = runTest {
        val broker = FakeBroker()
        val service = service(broker)
        service.connect()
        runCurrent()
        broker.session!!.onMessage("v2/json/devices/me/attributes", """{"shared":{"sensorAppInstallation":"other"}}""")
        runCurrent()
        assertEquals(ConnectionReason.BOUND_TO_ANOTHER_PHONE, (service.state.value as ConnectionState.Refused).reason)
    }

    @Test
    fun aRefusedTokenStopsRetrying() = runTest {
        val broker = FakeBroker().apply { failWith = MqttFailure.Kind.NOT_AUTHORIZED }
        val service = service(broker)
        service.connect()
        advanceTimeBy(300_000)
        assertEquals(ConnectionReason.TOKEN_REFUSED, (service.state.value as ConnectionState.Refused).reason)
        assertEquals(1, broker.attempts)
        // The user can try again.
        broker.failWith = null
        service.connect()
        runCurrent()
        assertEquals(ConnectionState.Connected, service.state.value)
    }

    @Test
    fun retriesWithGrowingDelayAndAtOnceWhenTheNetworkIsBack() = runTest {
        val broker = FakeBroker().apply { failWith = MqttFailure.Kind.UNREACHABLE }
        val service = service(broker)
        service.connect()
        runCurrent()
        assertEquals(ConnectionState.Waiting(ConnectionReason.SERVER_NOT_REACHABLE, 0, 1_000), service.state.value)
        advanceTimeBy(1_001)
        assertEquals(2, broker.attempts)
        assertEquals(ConnectionState.Waiting(ConnectionReason.SERVER_NOT_REACHABLE, 1_000, 3_000), service.state.value)
        network.value = false
        runCurrent()
        assertEquals(ConnectionReason.NO_NETWORK, (service.state.value as ConnectionState.Waiting).reason)
        advanceTimeBy(60_000)
        assertEquals(2, broker.attempts)
        broker.failWith = null
        network.value = true
        runCurrent()
        assertEquals(3, broker.attempts)
        assertEquals(ConnectionState.Connected, service.state.value)
    }

    @Test
    fun aLostConnectionIsRetriedAfterOneSecond() = runTest {
        val broker = FakeBroker()
        val service = service(broker)
        service.connect()
        runCurrent()
        broker.session!!.lose()
        runCurrent()
        assertEquals(ConnectionState.Waiting(ConnectionReason.CONNECTION_LOST, 0, 1_000), service.state.value)
        advanceTimeBy(1_001)
        assertEquals(ConnectionState.Connected, service.state.value)
    }

    @Test
    fun disconnectEndsEverything() = runTest {
        val broker = FakeBroker()
        val service = service(broker)
        service.connect()
        runCurrent()
        service.disconnect()
        runCurrent()
        assertEquals(ConnectionState.Disconnected, service.state.value)
        assertTrue(broker.session!!.disconnected)
        assertFalse(service.settings.value.connected)
    }

    @Test
    fun samplesAtTheSendRateAndDeliversTheQueue() = runTest {
        val broker = FakeBroker()
        val service = service(broker, Store(DeviceSettings(transmitting = true)))
        runCurrent()
        // Not connected: the sample waits in the queue.
        assertEquals(1, queue.status.value.count)
        service.connect()
        runCurrent()
        assertEquals(0, queue.status.value.count)
        assertEquals(
            """[{"ts":0,"values":{"batteryLevel":0.5,"charging":false}}]""",
            broker.published.single { it.first == "v2/json/devices/me/telemetry" }.second,
        )
        // On change: nothing changed, nothing is sent.
        advanceTimeBy(2_001)
        assertEquals(1, broker.topics().count { it == "v2/json/devices/me/telemetry" })
        Battery.level = 0.6
        advanceTimeBy(2_000)
        assertEquals("""[{"ts":4000,"values":{"batteryLevel":0.6}}]""", broker.published.last().second)
        Battery.level = 0.5
    }

    @Test
    fun aMessageThatIsNeverAcknowledgedIsDiscardedAfterThreeConnections() = runTest {
        val broker = FakeBroker().apply { acknowledge = false }
        val service = service(broker, Store(DeviceSettings(transmitting = true)))
        service.connect()
        runCurrent()
        repeat(3) {
            broker.session!!.lose()
            advanceTimeBy(1_001)
        }
        assertEquals(1, queue.status.value.discarded.count)
        service.disconnect()
    }

    @Test
    fun appliesSharedAttributesAndAnswersCommands() = runTest {
        val broker = FakeBroker("""{"shared":{"sensorAppInstallation":"$INSTALLATION","sendRate":10}}""")
        val service = service(broker)
        service.connect()
        runCurrent()
        assertEquals(10, service.settings.value.sendRate)
        assertFalse(service.setSendRate(5))
        broker.session!!.onMessage("v2/json/devices/me/rpc/request/7", """{"method":"setSendRate","params":{"seconds":5}}""")
        broker.session!!.onMessage("v2/json/devices/me/rpc/request/8", """{"method":"startTransmission"}""")
        runCurrent()
        assertTrue("v2/json/devices/me/rpc/response/7" to """{"error":"managed setting"}""" in broker.published)
        assertTrue("v2/json/devices/me/rpc/response/8" to """{"transmitting":true}""" in broker.published)
        assertTrue(service.settings.value.transmitting)
        // The changed client attributes are published again.
        assertTrue(broker.published.last { it.first == "v2/json/devices/me/attributes" }.second.contains(""""transmitting":true"""))
        broker.session!!.onMessage("v2/json/devices/me/attributes", """{"shared":{"sendRate":null}}""")
        runCurrent()
        assertTrue(service.setSendRate(5))
        assertEquals(5, service.settings.value.sendRate)
    }
}

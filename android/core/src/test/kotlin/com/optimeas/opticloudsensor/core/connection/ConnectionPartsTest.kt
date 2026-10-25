package com.optimeas.opticloudsensor.core.connection

import com.optimeas.opticloudsensor.core.Sample
import com.optimeas.opticloudsensor.core.TelemetryValue
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

class ReconnectDelayTest {
    @Test
    fun doublesUpToSixtySeconds() {
        assertEquals(listOf(1_000L, 2_000L, 4_000L, 8_000L, 16_000L, 32_000L, 60_000L, 60_000L), (1..8).map { ReconnectDelay.millis(it, 0.5) })
        assertEquals(60_000L, ReconnectDelay.millis(100, 0.5))
    }

    @Test
    fun variesByTwentyPercent() {
        assertEquals(800L, ReconnectDelay.millis(1, 0.0))
        assertEquals(1_199L, ReconnectDelay.millis(1, 0.9995))
        assertEquals(72_000L, ReconnectDelay.millis(10, 1.0))
    }
}

class DeviceMessagesTest {
    @Test
    fun attributeRequestIsOneString() {
        assertEquals("""{"sharedKeys":"sendRate,sensors,dashboard,sensorAppInstallation"}""", DeviceMessages.attributeRequest(DeviceMessages.REQUESTED_SHARED_KEYS))
    }

    @Test
    fun requestIdIsPositive() {
        assertEquals(5L, DeviceMessages.requestId("v2/json/devices/me/rpc/request/5", DeviceMessages.RPC_REQUEST_PREFIX))
        assertNull(DeviceMessages.requestId("v2/json/devices/me/rpc/request/0", DeviceMessages.RPC_REQUEST_PREFIX))
        assertNull(DeviceMessages.requestId("v2/json/devices/me/rpc/request/x", DeviceMessages.RPC_REQUEST_PREFIX))
        assertNull(DeviceMessages.requestId("v2/json/devices/me/attributes/response/5", DeviceMessages.RPC_REQUEST_PREFIX))
    }

    @Test
    fun readsSharedAttributesOfChangesAndAnswers() {
        assertEquals(mapOf("sendRate" to JsonPrimitive(5), "oldKey" to JsonNull), DeviceMessages.sharedAttributes("""{"shared":{"sendRate":5,"oldKey":null}}"""))
        assertEquals(mapOf("sendRate" to JsonPrimitive(5)), DeviceMessages.sharedAttributes("""{"client":{"appVersion":"1"},"shared":{"sendRate":5}}"""))
        assertEquals(emptyMap(), DeviceMessages.sharedAttributes("""{"client":{}}"""))
        assertNull(DeviceMessages.sharedAttributes("not json"))
        assertNull(DeviceMessages.sharedAttributes("""{"shared":3}"""))
    }

    @Test
    fun readsCommands() {
        assertEquals(DeviceMessages.Command("ping", JsonObject(emptyMap())), DeviceMessages.command("""{"method":"ping","params":{}}"""))
        assertEquals(DeviceMessages.Command("ping", JsonNull), DeviceMessages.command("""{"method":"ping"}"""))
        assertNull(DeviceMessages.command("""{"method":3}"""))
        assertNull(DeviceMessages.command("[]"))
    }

    @Test
    fun clientAttributesLeaveOutValuesThatCannotBeSent() {
        val attributes = mapOf(
            "appVersion" to TelemetryValue.Text("0.1.0"),
            "sendRate" to TelemetryValue.Number(2.0),
            "bad" to TelemetryValue.Number(Double.NaN),
            "transmitting" to TelemetryValue.Bool(false),
        )
        assertEquals("""{"appVersion":"0.1.0","sendRate":2,"transmitting":false}""", DeviceMessages.clientAttributes(attributes))
    }
}

class SharedAttributesTest {
    private val settings = DeviceSettings()

    @Test
    fun appliesUsableValuesAndManagesThem() {
        val result = SharedAttributes.apply(
            settings,
            mapOf("sendRate" to JsonPrimitive(5), "sensors" to JsonPrimitive("device"), "dashboard" to JsonPrimitive("abc"), "other" to JsonPrimitive(1)),
            complete = false,
        )
        assertEquals(DeviceSettings(sendRate = 5, sensors = "device", dashboard = "abc", managed = setOf("sendRate", "sensors", "dashboard")), result.settings)
        assertEquals(emptyMap(), result.ignored)
    }

    @Test
    fun ignoresValuesItCannotUse() {
        val managed = settings.copy(managed = setOf("sendRate"))
        for (value in listOf(JsonPrimitive(0), JsonPrimitive(3601), JsonPrimitive(2.5), JsonPrimitive("5"), JsonPrimitive(true), JsonObject(emptyMap()))) {
            val result = SharedAttributes.apply(managed, mapOf("sendRate" to value), complete = false)
            assertEquals(managed, result.settings, "sendRate $value")
            assertEquals(mapOf("sendRate" to value), result.ignored)
        }
        val unknownKey = SharedAttributes.apply(settings, mapOf("sensors" to JsonPrimitive("device,nonsense")), complete = false)
        assertEquals(settings, unknownKey.settings)
        assertEquals(1, unknownKey.ignored.size)
    }

    @Test
    fun acceptsWholeNumbersWrittenWithDecimals() {
        assertEquals(60, SharedAttributes.apply(settings, mapOf("sendRate" to JsonPrimitive(60.0)), complete = false).settings.sendRate)
    }

    @Test
    fun deletedAttributeReleasesTheSettingAndKeepsItsValue() {
        val managed = settings.copy(sendRate = 5, managed = setOf("sendRate", "dashboard"))
        assertEquals(managed.copy(managed = setOf("dashboard")), SharedAttributes.apply(managed, mapOf("sendRate" to JsonNull), complete = false).settings)
        // A key missing from a change says nothing; missing from the answer after connect, it was deleted.
        assertEquals(managed, SharedAttributes.apply(managed, emptyMap(), complete = false).settings)
        assertEquals(managed.copy(managed = emptySet()), SharedAttributes.apply(managed, emptyMap(), complete = true).settings)
    }
}

class CommandsTest {
    private val settings = DeviceSettings(sendRate = 5)

    private fun run(json: String, settings: DeviceSettings = this.settings) =
        Commands.carryOut(DeviceMessages.command(json)!!, settings, "device,location")

    @Test
    fun answersTheCommandsOfTheSpecification() {
        assertEquals("""{"pong":true}""", run("""{"method":"ping","params":{}}""").answer.toString())
        assertEquals("""{"transmitting":false,"sendRate":5,"sensors":"device,location"}""", run("""{"method":"getState"}""").answer.toString())
        assertTrue(run("""{"method":"startTransmission"}""").settings.transmitting)
        assertEquals(false, run("""{"method":"stopTransmission"}""", settings.copy(transmitting = true)).settings.transmitting)
        val rate = run("""{"method":"setSendRate","params":{"seconds":10}}""")
        assertEquals("""{"sendRate":10}""", rate.answer.toString())
        assertEquals(10, rate.settings.sendRate)
        val now = run("""{"method":"sendNow"}""")
        assertEquals("""{"sent":true}""", now.answer.toString())
        assertTrue(now.sendNow)
    }

    @Test
    fun refusesWhatItCannotCarryOut() {
        assertEquals("""{"error":"unknown method"}""", run("""{"method":"reboot"}""").answer.toString())
        for (params in listOf("{}", """{"seconds":0}""", """{"seconds":"5"}""", "5")) {
            val result = run("""{"method":"setSendRate","params":$params}""")
            assertEquals("""{"error":"invalid params"}""", result.answer.toString())
            assertEquals(settings, result.settings)
        }
        val managed = settings.copy(managed = setOf("sendRate"))
        val result = run("""{"method":"setSendRate","params":{"seconds":10}}""", managed)
        assertEquals("""{"error":"managed setting"}""", result.answer.toString())
        assertEquals(managed, result.settings)
    }
}

class TelemetryQueueTest {
    private fun sample(ts: Long) = Sample(ts, mapOf("batteryLevel" to TelemetryValue.Number(0.5)))

    @Test
    fun deliversOldestFirstAndRemovesOnAcknowledgment() {
        val queue = TelemetryQueue(MemoryQueueStore())
        queue.append(sample(2))
        queue.append(sample(1))
        val message = queue.next()!!
        assertEquals("""[{"ts":1,"values":{"batteryLevel":0.5}},{"ts":2,"values":{"batteryLevel":0.5}}]""", message.payload)
        assertEquals(2, queue.status.value.count)
        assertEquals(1, queue.status.value.oldestTs)
        queue.acknowledged(message)
        assertEquals(0, queue.status.value.count)
        assertNull(queue.next())
    }

    @Test
    fun splitsAtThirtyTwoKibibytes() {
        val queue = TelemetryQueue(MemoryQueueStore())
        val big = "x".repeat(10_000)
        repeat(4) { queue.append(Sample(it.toLong(), mapOf("note" to TelemetryValue.Text(big)))) }
        val first = queue.next()!!
        assertEquals(3, first.samples.size)
        assertTrue(first.payload.toByteArray().size <= 32_768)
    }

    @Test
    fun discardsTheOldestWhenFull() {
        val size = TelemetryQueue(MemoryQueueStore()).apply { append(sample(0)) }.status.value.bytes
        val queue = TelemetryQueue(MemoryQueueStore(), maxBytes = size * 3)
        (1L..5L).forEach { queue.append(sample(it)) }
        val status = queue.status.value
        assertEquals(3, status.count)
        assertEquals(Discarded(2, 1, 2), status.discarded)
        assertEquals(3, status.oldestTs)
        queue.resetDiscarded()
        assertEquals(Discarded(), queue.status.value.discarded)
    }

    @Test
    fun discardsAMessageAfterThreeClosedConnectionsInARow() {
        val queue = TelemetryQueue(MemoryQueueStore())
        queue.append(sample(1))
        repeat(2) { queue.connectionClosed(queue.next()!!) }
        assertEquals(1, queue.status.value.count)
        queue.connectionClosed(queue.next()!!)
        assertEquals(0, queue.status.value.count)
        assertEquals(1, queue.status.value.discarded.count)
    }

    @Test
    fun anAcknowledgmentResetsTheCount() {
        val queue = TelemetryQueue(MemoryQueueStore())
        queue.append(sample(1))
        repeat(2) { queue.connectionClosed(queue.next()!!) }
        queue.acknowledged(queue.next()!!)
        queue.append(sample(2))
        repeat(2) { queue.connectionClosed(queue.next()!!) }
        assertEquals(1, queue.status.value.count)
    }
}

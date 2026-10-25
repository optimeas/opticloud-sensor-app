package com.optimeas.opticloudsensor.core

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.double
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/** Runs every case of every shared test vector file (see `docs/spec/README.md`, Test vectors). */
class VectorTest {
    @Test
    fun telemetry() = Vectors.run("telemetry.json") { case ->
        val samples = case.getValue("samples").samples()
        assertEquals(case.string("topic"), Telemetry.TOPIC)
        val payload = Json.parseToJsonElement(Telemetry.payload(samples))
        assertJsonEquals(case.getValue("payload"), payload)
    }

    @Test
    fun selection() = Vectors.run("selection.json") { case ->
        val offered = case.getValue("offered").jsonArray.map { it.jsonPrimitive.content }.toSet()
        val selection = Selection.parse(case.string("selection"))
        if (!case.getValue("valid").jsonPrimitive.boolean) {
            assertNull(selection, "the selection must be invalid")
            return@run
        }
        assertNotNull(selection, "the selection must be valid")
        assertEquals(case.getValue("items").jsonArray.map { it.jsonPrimitive.content }, selection.items(offered))
        assertEquals(
            case.getValue("reported").jsonArray.map { it.jsonPrimitive.content }.toSet(),
            selection.report(offered).toSet(),
        )
    }

    @Test
    fun rounding() = Vectors.run("rounding.json") { case ->
        val resolution = assertNotNull(Resolution.ofStep(case.getValue("resolution").jsonPrimitive.double))
        assertEquals(resolution, Catalog.resolutionOf(case.string("key")), "resolution in the catalog")
        val rounded = resolution.round(case.getValue("value").jsonPrimitive.double)
        assertJsonEquals(case.getValue("rounded"), JsonCodec.number(rounded))
        case["written"]?.let { assertEquals(it.jsonPrimitive.content, JsonCodec.number(rounded).toString(), "written") }
    }

    @Test
    fun onChange() = Vectors.run("on-change.json") { case ->
        val filter = SendFilter(SendMode.fromKey(case.string("mode"))!!)
        val sent = case.getValue("ticks").jsonArray.mapNotNull { element ->
            val tick = element.jsonObject
            if (tick["selectionChanged"]?.jsonPrimitive?.booleanOrNull == true) filter.selectionChanged()
            val measured = tick.getValue("values").jsonObject.mapValues { (_, value) -> value.telemetryValue() }
            filter.sample(tick.getValue("ts").jsonPrimitive.long, measured)
        }
        assertJsonEquals(case.getValue("sent"), JsonArray(sent.map(JsonCodec::encode)))
    }

    @Test
    fun aggregation() = Vectors.run("aggregation.json") { case ->
        val key = case.string("key")
        val aggregate = Aggregate()
        case["measurements"]?.jsonArray?.forEach { aggregate.add(it.jsonPrimitive.double) }
        case["measurements3"]?.jsonArray?.forEach { triple ->
            val (x, y, z) = triple.jsonArray.map { it.jsonPrimitive.double }
            aggregate.add(Aggregate.magnitude(x, y, z))
        }
        val values = aggregate.values(key, Catalog.resolutionOf(key))
        assertJsonEquals(case.getValue("values"), JsonObject(values.mapValues { (_, value) -> JsonCodec.encode(value) }))
    }

    @Test
    fun queueBatching() = Vectors.run("queue-batching.json") { case ->
        val queue = case.getValue("queue").samples()
        val messages = Telemetry.messages(queue, case.getValue("maxPayloadBytes").jsonPrimitive.int)
        assertJsonEquals(
            case.getValue("messages"),
            JsonArray(messages.map { Json.parseToJsonElement(Telemetry.payload(it)) }),
        )
    }

    @Test
    fun journalNote() = Vectors.run("journal-note.json") { case ->
        val entry = case.getValue("entry").jsonObject
        val claims = case.getValue("claims").jsonObject
        val journalEntry = JournalEntry(
            title = entry.string("title"),
            text = entry.string("text"),
            status = JournalEntry.Status.valueOf(entry.string("status")),
            priority = JournalEntry.Priority.valueOf(entry.string("priority")),
            savedAt = entry.getValue("savedAt").jsonPrimitive.long,
            utcOffsetMinutes = entry.getValue("utcOffsetMinutes").jsonPrimitive.int,
            latitude = (entry["latitude"] as JsonPrimitive?)?.double,
            longitude = (entry["longitude"] as JsonPrimitive?)?.double,
        )
        val body = JournalNote.body(
            entry = journalEntry,
            claims = SessionClaims(
                tenantId = claims.string("tenantId"),
                projectId = claims.string("projectId"),
                authorityDataId = claims.string("authorityDataId"),
            ),
            deviceId = case.string("deviceId"),
        )
        assertJsonEquals(case.getValue("body"), body)
    }
}

package com.optimeas.opticloudsensor.core

import java.io.File
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import kotlin.test.assertEquals
import kotlin.test.fail

/** Loads the shared test vectors from `docs/spec/vectors/` (see `docs/spec/README.md`, Test vectors). */
object Vectors {
    val directory: File = File(
        System.getProperty("vectorsDir") ?: error("The system property vectorsDir is not set; run the tests through Gradle."),
    )

    /** The file names the tests cover. [VectorFileTest] checks that no file is left out. */
    val covered = setOf(
        "telemetry.json",
        "selection.json",
        "rounding.json",
        "on-change.json",
        "aggregation.json",
        "queue-batching.json",
        "journal-note.json",
    )

    fun cases(file: String): List<JsonObject> =
        Json.parseToJsonElement(File(directory, file).readText()).jsonObject.getValue("cases").jsonArray.map { it.jsonObject }

    /** Runs [check] for every case and reports all failing cases together, by name. */
    fun run(file: String, check: (JsonObject) -> Unit) {
        val failures = cases(file).mapNotNull { case ->
            val name = case.getValue("name").jsonPrimitive.content
            try {
                check(case)
                null
            } catch (e: AssertionError) {
                "$name: ${e.message}"
            }
        }
        if (failures.isNotEmpty()) fail("$file\n" + failures.joinToString("\n"))
    }
}

fun JsonObject.string(key: String): String = getValue(key).jsonPrimitive.content

fun JsonObject.sample(): Sample = Sample(
    ts = getValue("ts").jsonPrimitive.long,
    values = getValue("values").jsonObject.mapValues { (_, value) -> value.telemetryValue() },
)

fun JsonElement.samples(): List<Sample> = jsonArray.map { it.jsonObject.sample() }

fun JsonElement.telemetryValue(): TelemetryValue {
    val primitive = jsonPrimitive
    return when {
        primitive.isString -> TelemetryValue.Text(primitive.content)
        primitive.booleanOrNull != null -> TelemetryValue.Bool(primitive.booleanOrNull!!)
        else -> TelemetryValue.Number(primitive.doubleOrNull ?: error("not a value: $primitive"))
    }
}

/** Compares JSON values: order of object members does not matter, numbers are compared as numbers. */
fun assertJsonEquals(expected: JsonElement, actual: JsonElement, path: String = "$") {
    when (expected) {
        is JsonObject -> {
            if (actual !is JsonObject) fail("$path: expected an object, got $actual")
            assertEquals(expected.keys, actual.keys, "$path: members")
            for (key in expected.keys) assertJsonEquals(expected.getValue(key), actual.getValue(key), "$path.$key")
        }
        is JsonArray -> {
            if (actual !is JsonArray) fail("$path: expected an array, got $actual")
            assertEquals(expected.size, actual.size, "$path: length")
            expected.indices.forEach { assertJsonEquals(expected[it], actual[it], "$path[$it]") }
        }
        is JsonNull -> assertEquals<JsonElement>(JsonNull, actual, path)
        is JsonPrimitive -> {
            if (actual !is JsonPrimitive || actual is JsonNull) fail("$path: expected $expected, got $actual")
            if (expected.isString || expected.booleanOrNull != null) {
                assertEquals(expected, actual, path)
            } else {
                if (actual.isString) fail("$path: expected the number $expected, got the string $actual")
                // 0, 0.0, and -0.0 are equal
                assertEquals(expected.doubleOrNull!! + 0.0, actual.doubleOrNull!! + 0.0, "$path: $expected != $actual")
            }
        }
    }
}

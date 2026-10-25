package com.optimeas.opticloudsensor.core

import java.math.BigDecimal
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonUnquotedLiteral

/** Writes values and samples as JSON (see `docs/spec/messages.md`, Telemetry). */
object JsonCodec {
    /**
     * A number as JSON: in plain notation without exponent, a whole number without decimals,
     * and a negative zero as `0`. A rounded value therefore has no more decimals than its resolution.
     */
    @OptIn(ExperimentalSerializationApi::class)
    fun number(value: Double): JsonPrimitive {
        require(value.isFinite()) { "A number that is not finite cannot be sent." }
        if (value == 0.0) return JsonUnquotedLiteral("0")
        // Double.toString gives the shortest decimal that reads back as the same double.
        return JsonUnquotedLiteral(BigDecimal(value.toString()).stripTrailingZeros().toPlainString())
    }

    fun encode(value: TelemetryValue): JsonPrimitive = when (value) {
        is TelemetryValue.Number -> number(value.value)
        is TelemetryValue.Bool -> JsonPrimitive(value.value)
        is TelemetryValue.Text -> JsonPrimitive(value.value)
    }

    fun encode(sample: Sample): JsonObject = JsonObject(
        mapOf(
            "ts" to JsonPrimitive(sample.ts),
            "values" to JsonObject(sample.values.mapValues { (_, value) -> encode(value) }),
        ),
    )

    /** JSON without white space. */
    fun compact(element: JsonElement): String = element.toString()
}

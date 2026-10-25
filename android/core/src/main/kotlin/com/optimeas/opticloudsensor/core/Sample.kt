package com.optimeas.opticloudsensor.core

/**
 * A value of a telemetry sample or a client attribute: a number, a boolean, or a string
 * (see `docs/spec/messages.md`, Telemetry).
 */
sealed interface TelemetryValue {
    data class Number(val value: Double) : TelemetryValue
    data class Bool(val value: Boolean) : TelemetryValue
    data class Text(val value: String) : TelemetryValue

    /** Whether the value may be sent. A number that is not finite cannot be sent. */
    val isSendable: Boolean
        get() = this !is Number || value.isFinite()
}

/** Values measured at one moment. [ts] is the moment of measurement in milliseconds since 1970. */
data class Sample(val ts: Long, val values: Map<String, TelemetryValue>)

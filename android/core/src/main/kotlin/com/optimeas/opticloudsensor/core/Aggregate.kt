package com.optimeas.opticloudsensor.core

import kotlin.math.sqrt

/** Mean, minimum, and maximum of the measurements of one value between two ticks (see `docs/spec/sensors.md`, Sampling). */
class Aggregate {
    var count = 0
        private set
    private var sum = 0.0
    private var minimum = Double.POSITIVE_INFINITY
    private var maximum = Double.NEGATIVE_INFINITY

    fun add(value: Double) {
        if (!value.isFinite()) return
        count++
        sum += value
        minimum = minOf(minimum, value)
        maximum = maxOf(maximum, value)
    }

    /** The values to send for [key], rounded to [resolution] only after mean, minimum, and maximum are taken. */
    fun values(key: String, resolution: Resolution?): Map<String, TelemetryValue> {
        if (count == 0) return emptyMap()
        fun rounded(value: Double) = TelemetryValue.Number(resolution?.round(value) ?: value)
        return mapOf(
            key to rounded(sum / count),
            key + "Min" to rounded(minimum),
            key + "Max" to rounded(maximum),
        )
    }

    companion object {
        /** The magnitude of a vector with three axes. */
        fun magnitude(x: Double, y: Double, z: Double): Double = sqrt(x * x + y * y + z * z)
    }
}

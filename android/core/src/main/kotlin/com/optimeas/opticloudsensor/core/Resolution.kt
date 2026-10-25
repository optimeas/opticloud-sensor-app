package com.optimeas.opticloudsensor.core

import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sign
import kotlin.math.truncate

/**
 * The step to which a number is rounded before it is sent: a power of ten, 10 to the power of [exponent]
 * (see `docs/spec/sensors.md`, Sending on change).
 */
data class Resolution(val exponent: Int) {
    val step: Double get() = 10.0.pow(exponent)

    /**
     * Divides by the step, rounds half away from zero, and multiplies by the step. For a step below 1 the
     * value is multiplied by the whole power of ten 1 / step and divided by it afterwards, because that
     * power of ten is exact in floating point and the step is not.
     */
    fun round(value: Double): Double {
        val result = if (exponent < 0) {
            val scale = 10.0.pow(-exponent)
            roundHalfAwayFromZero(value * scale) / scale
        } else {
            roundHalfAwayFromZero(value / step) * step
        }
        return result + 0.0 // no negative zero
    }

    companion object {
        /** The resolution for a step such as 0.01 or 1000, or null if the step is not a power of ten. */
        fun ofStep(step: Double): Resolution? {
            if (step <= 0.0 || !step.isFinite()) return null
            val exponent = log10(step).roundToInt()
            return if (abs(10.0.pow(exponent) - step) <= step * 1e-9) Resolution(exponent) else null
        }

        // Not floor(value + 0.5): that addition can round up, for example for 0.49999999999999994.
        private fun roundHalfAwayFromZero(value: Double): Double {
            val whole = truncate(value)
            return if (abs(value - whole) >= 0.5) whole + sign(value) else whole
        }
    }
}

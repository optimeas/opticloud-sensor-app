package com.optimeas.opticloudsensor.core

import kotlin.test.Test
import kotlin.test.assertEquals

/** How numbers are written in JSON (see `docs/spec/sensors.md`, Sending on change). */
class JsonCodecTest {
    private fun written(value: Double) = JsonCodec.number(value).toString()

    @Test
    fun wholeNumbersHaveNoDecimals() {
        assertEquals("63", written(63.0))
        assertEquals("13000", written(13000.0))
        assertEquals("-86", written(-86.0))
    }

    @Test
    fun negativeZeroIsWrittenAsZero() {
        assertEquals("0", written(-0.0))
    }

    @Test
    fun noExponent() {
        assertEquals("12000000000", written(1.2e10))
        assertEquals("0.00001", written(1e-5))
    }

    @Test
    fun roundedValuesHaveNoMoreDecimalsThanTheResolution() {
        assertEquals("0.3", written(Resolution(-1).round(0.1 + 0.2)))
        assertEquals("1013.2", written(Resolution(-1).round(1013.2468)))
        assertEquals("47.37689", written(Resolution(-5).round(47.376887)))
    }

    @Test
    fun payloadHasNoWhiteSpace() {
        val sample = Sample(1760000000000, mapOf("network" to TelemetryValue.Text("wifi"), "steps" to TelemetryValue.Number(12.0)))
        assertEquals("""[{"ts":1760000000000,"values":{"network":"wifi","steps":12}}]""", Telemetry.payload(listOf(sample)))
        assertEquals(Telemetry.payload(listOf(sample)).toByteArray().size - 2, Telemetry.encodedSize(sample))
    }
}

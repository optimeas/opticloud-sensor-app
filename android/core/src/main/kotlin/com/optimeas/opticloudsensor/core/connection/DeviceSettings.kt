package com.optimeas.opticloudsensor.core.connection

import com.optimeas.opticloudsensor.core.Selection
import com.optimeas.opticloudsensor.core.SendMode
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull

/**
 * The settings of transmission (see `docs/spec/configuration.md`). [managed] holds the keys of the shared
 * attributes that exist: those settings are managed by optiCLOUD and locked on the phone.
 */
data class DeviceSettings(
    val sendRate: Int = DEFAULT_SEND_RATE,
    val sendMode: SendMode = SendMode.ON_CHANGE,
    val sensors: String = DEFAULT_SENSORS,
    val dashboard: String? = null,
    val connected: Boolean = false,
    val transmitting: Boolean = false,
    val managed: Set<String> = emptySet(),
) {
    val selection: Selection get() = Selection.parse(sensors) ?: Selection.parse("")!!

    companion object {
        const val DEFAULT_SEND_RATE = 2
        const val DEFAULT_SENSORS = "device,location"
        val SEND_RATES = 1..3600

        /** The shared attributes that are settings. */
        val MANAGED_KEYS = listOf("sendRate", "sensors", "dashboard")
    }
}

/** The result of applying shared attributes: the new settings and the values that could not be used. */
data class SharedAttributesResult(val settings: DeviceSettings, val ignored: Map<String, JsonElement>)

object SharedAttributes {
    /**
     * Applies shared attributes to the settings (see `docs/spec/messages.md`, Changes of shared attributes).
     * [complete] is true for the answer to the request after a connect: a setting whose key is missing there was
     * deleted while the app was offline.
     */
    fun apply(settings: DeviceSettings, attributes: Map<String, JsonElement>, complete: Boolean): SharedAttributesResult {
        var result = settings
        val ignored = mutableMapOf<String, JsonElement>()
        for (key in DeviceSettings.MANAGED_KEYS) {
            val value = attributes[key]
            if (value == null) {
                if (complete) result = result.copy(managed = result.managed - key)
                continue
            }
            if (value == JsonNull) {
                result = result.copy(managed = result.managed - key)
                continue
            }
            val applied = when (key) {
                "sendRate" -> sendRate(value)?.let { result.copy(sendRate = it) }
                "sensors" -> text(value)?.takeIf { Selection.parse(it) != null }?.let { result.copy(sensors = it) }
                else -> text(value)?.let { result.copy(dashboard = it) }
            }
            if (applied == null) {
                ignored[key] = value
            } else {
                result = applied.copy(managed = applied.managed + key)
            }
        }
        return SharedAttributesResult(result, ignored)
    }

    /** A send rate in whole seconds within the allowed range, or null. */
    fun sendRate(value: JsonElement?): Int? {
        val number = (value as? JsonPrimitive)?.takeIf { !it.isString }?.doubleOrNull ?: return null
        if (number != Math.rint(number) || number.toInt().toDouble() != number) return null
        return number.toInt().takeIf { it in DeviceSettings.SEND_RATES }
    }

    private fun text(value: JsonElement): String? = (value as? JsonPrimitive)?.takeIf { it.isString }?.content
}

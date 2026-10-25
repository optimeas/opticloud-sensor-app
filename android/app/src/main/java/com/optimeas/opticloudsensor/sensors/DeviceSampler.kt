package com.optimeas.opticloudsensor.sensors

import android.content.Context
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.PowerManager
import android.telephony.TelephonyManager
import com.optimeas.opticloudsensor.connection.NetworkMonitor
import com.optimeas.opticloudsensor.core.TelemetryValue
import com.optimeas.opticloudsensor.core.connection.SensorSource

/**
 * The sampled values of the group `device` (see `docs/spec/sensors.md`, device). `dataVolume` is not offered
 * yet: the app does not count its data volume so far.
 */
class DeviceSampler(context: Context, private val network: NetworkMonitor) : SensorSource {
    private val battery = context.getSystemService(BatteryManager::class.java)
    private val power = context.getSystemService(PowerManager::class.java)
    private val telephony = context.getSystemService(TelephonyManager::class.java)
        .takeIf { context.packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY) }

    override val offered: Set<String> = buildSet {
        addAll(listOf("batteryLevel", "charging", "network", "thermalState", "powerSaving"))
        if (telephony != null) add("cellularSignal")
    }

    override fun measure(items: List<String>): Map<String, TelemetryValue> = buildMap {
        for (item in items) {
            val value = when (item) {
                "batteryLevel" -> battery.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                    .takeIf { it in 0..100 }?.let { TelemetryValue.Number(it / 100.0) }
                "charging" -> TelemetryValue.Bool(battery.isCharging)
                "network" -> TelemetryValue.Text(network.kind.value.key)
                "thermalState" -> TelemetryValue.Text(thermalState(power.currentThermalStatus))
                "powerSaving" -> TelemetryValue.Bool(power.isPowerSaveMode)
                "cellularSignal" -> cellularSignal()?.let { TelemetryValue.Number(it.toDouble()) }
                else -> null
            }
            if (value != null) put(item, value)
        }
    }

    /** The strongest signal of the mobile network in dBm, or null without one. Needs no permission. */
    private fun cellularSignal(): Int? = telephony?.signalStrength?.cellSignalStrengths
        ?.map { it.dbm }
        ?.filter { it != Int.MAX_VALUE && it < 0 }
        ?.maxOrNull()

    private fun thermalState(status: Int): String = when (status) {
        PowerManager.THERMAL_STATUS_NONE -> "nominal"
        PowerManager.THERMAL_STATUS_LIGHT -> "fair"
        PowerManager.THERMAL_STATUS_MODERATE -> "serious"
        else -> "critical"
    }
}

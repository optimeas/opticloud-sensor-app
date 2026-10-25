package com.optimeas.opticloudsensor.storage

import android.content.Context
import androidx.core.content.edit
import com.optimeas.opticloudsensor.core.SendMode
import com.optimeas.opticloudsensor.core.api.ServerAddress
import com.optimeas.opticloudsensor.core.connection.DeviceSettings
import com.optimeas.opticloudsensor.core.connection.SettingsStore
import java.util.UUID

/** A tenant, project, or device as the app remembers it: identifier and name. */
data class Named(val id: String, val name: String)

/** The device the phone sends to, with the tenant and project it was picked in. */
data class DeviceChoice(val tenant: Named, val project: Named, val device: Named)

/** Settings that are not secret (see `docs/spec/configuration.md`). */
class Settings(context: Context) : SettingsStore {
    private val preferences = context.getSharedPreferences("settings", Context.MODE_PRIVATE)

    var address: ServerAddress
        get() = preferences.getString(ADDRESS, null)?.let(ServerAddress::parse) ?: ServerAddress.OFFICIAL
        set(value) = preferences.edit { putString(ADDRESS, value.text) }

    var deviceChoice: DeviceChoice?
        get() {
            fun named(prefix: String): Named? {
                val id = preferences.getString("$prefix.id", null) ?: return null
                return Named(id, preferences.getString("$prefix.name", null) ?: "")
            }
            return DeviceChoice(named(TENANT) ?: return null, named(PROJECT) ?: return null, named(DEVICE) ?: return null)
        }
        set(value) = preferences.edit {
            for ((prefix, named) in listOf(TENANT to value?.tenant, PROJECT to value?.project, DEVICE to value?.device)) {
                if (named == null) {
                    remove("$prefix.id")
                    remove("$prefix.name")
                } else {
                    putString("$prefix.id", named.id)
                    putString("$prefix.name", named.name)
                }
            }
        }

    /** The MQTT client identifier: a random UUID created once and kept (see `docs/spec/connection.md`). */
    val clientId: String
        get() = preferences.getString(CLIENT_ID, null)
            ?: UUID.randomUUID().toString().also { preferences.edit { putString(CLIENT_ID, it) } }

    override fun load(): DeviceSettings {
        val defaults = DeviceSettings()
        return DeviceSettings(
            sendRate = preferences.getInt(SEND_RATE, defaults.sendRate),
            sendMode = preferences.getString(SEND_MODE, null)?.let(SendMode::fromKey) ?: defaults.sendMode,
            sensors = preferences.getString(SENSORS, null) ?: defaults.sensors,
            dashboard = preferences.getString(DASHBOARD, null),
            connected = preferences.getBoolean(CONNECTED, defaults.connected),
            transmitting = preferences.getBoolean(TRANSMITTING, defaults.transmitting),
            managed = preferences.getStringSet(MANAGED, null)?.toSet() ?: defaults.managed,
        )
    }

    override fun save(settings: DeviceSettings) = preferences.edit {
        putInt(SEND_RATE, settings.sendRate)
        putString(SEND_MODE, settings.sendMode.key)
        putString(SENSORS, settings.sensors)
        putString(DASHBOARD, settings.dashboard)
        putBoolean(CONNECTED, settings.connected)
        putBoolean(TRANSMITTING, settings.transmitting)
        putStringSet(MANAGED, settings.managed)
    }

    private companion object {
        const val ADDRESS = "address"
        const val TENANT = "tenant"
        const val PROJECT = "project"
        const val DEVICE = "device"
        const val CLIENT_ID = "clientId"
        const val SEND_RATE = "sendRate"
        const val SEND_MODE = "sendMode"
        const val SENSORS = "sensors"
        const val DASHBOARD = "dashboard"
        const val CONNECTED = "connected"
        const val TRANSMITTING = "transmitting"
        const val MANAGED = "managed"
    }
}

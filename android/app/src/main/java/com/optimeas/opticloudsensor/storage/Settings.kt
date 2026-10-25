package com.optimeas.opticloudsensor.storage

import android.content.Context
import androidx.core.content.edit
import com.optimeas.opticloudsensor.core.api.ServerAddress

/** A tenant, project, or device as the app remembers it: identifier and name. */
data class Named(val id: String, val name: String)

/** The device the phone sends to, with the tenant and project it was picked in. */
data class DeviceChoice(val tenant: Named, val project: Named, val device: Named)

/** Settings that are not secret (see `docs/spec/configuration.md`). */
class Settings(context: Context) {
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

    private companion object {
        const val ADDRESS = "address"
        const val TENANT = "tenant"
        const val PROJECT = "project"
        const val DEVICE = "device"
    }
}

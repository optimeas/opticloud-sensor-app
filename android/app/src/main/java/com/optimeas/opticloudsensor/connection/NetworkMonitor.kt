package com.optimeas.opticloudsensor.connection

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** The kind of network the system uses, as the item `network` writes it (see `docs/spec/sensors.md`, device). */
enum class NetworkKind(val key: String) { WIFI("wifi"), CELLULAR("cellular"), OTHER("other"), NONE("none") }

/** Follows the default network of the system. */
class NetworkMonitor(context: Context) {
    private val manager = context.getSystemService(ConnectivityManager::class.java)

    private val _kind = MutableStateFlow(kindOf(manager.getNetworkCapabilities(manager.activeNetwork)))
    val kind: StateFlow<NetworkKind> = _kind.asStateFlow()

    private val _available = MutableStateFlow(_kind.value != NetworkKind.NONE)

    /** Whether there is a network. The connection retries at once when it comes back. */
    val available: StateFlow<Boolean> = _available.asStateFlow()

    init {
        manager.registerDefaultNetworkCallback(object : ConnectivityManager.NetworkCallback() {
            override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) = set(kindOf(capabilities))

            override fun onLost(network: Network) = set(NetworkKind.NONE)
        })
    }

    private fun set(kind: NetworkKind) {
        _kind.value = kind
        _available.value = kind != NetworkKind.NONE
    }

    private fun kindOf(capabilities: NetworkCapabilities?): NetworkKind = when {
        capabilities == null || !capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) -> NetworkKind.NONE
        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> NetworkKind.WIFI
        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> NetworkKind.CELLULAR
        else -> NetworkKind.OTHER
    }
}

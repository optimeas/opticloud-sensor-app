package com.optimeas.opticloudsensor.storage

import android.content.Context
import com.optimeas.opticloudsensor.core.api.OptiCloudClient
import com.optimeas.opticloudsensor.core.api.ServerAddress
import com.optimeas.opticloudsensor.core.api.TokenPair
import com.optimeas.opticloudsensor.storage.SecretStore.Key
import java.util.UUID
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/** What the user interface shows of the app's lasting state. */
data class AppState(val address: ServerAddress, val signedIn: Boolean, val device: DeviceChoice?)

/**
 * The lasting state of the app: the address, the user's session, the chosen device and its token, and the
 * installation identifier (see `docs/spec/configuration.md`, Stored data). One instance per process.
 */
class AppModel(context: Context) {
    private val settings = Settings(context)
    private val secrets = SecretStore(context)

    /** The random identifier of this installation; it binds devices to this phone. Lower case with hyphens. */
    val installationId: String = secrets.get(Key.INSTALLATION_ID)
        ?: UUID.randomUUID().toString().also { secrets.set(Key.INSTALLATION_ID, it) }

    var client: OptiCloudClient = createClient(settings.address, storedTokens())
        private set

    private val _state = MutableStateFlow(AppState(settings.address, client.isSignedIn, settings.deviceChoice))
    val state: StateFlow<AppState> = _state.asStateFlow()

    /** The access token of the chosen device. Never shown and never logged. */
    val deviceToken: String? get() = secrets.get(Key.DEVICE_TOKEN)

    /**
     * Changes the address of the web application. This signs the user out and forgets the device, because the
     * device belongs to the old server (see `docs/spec/configuration.md`, Signing out and changing the device).
     */
    fun changeAddress(address: ServerAddress) {
        if (address == settings.address) return
        client.signOut()
        forgetDevice()
        settings.address = address
        client = createClient(address, null)
        _state.update { AppState(address, signedIn = false, device = null) }
    }

    /** Deletes the session tokens. The device, its token, and the settings stay. */
    fun signOut() = client.signOut()

    fun setDevice(choice: DeviceChoice, token: String) {
        secrets.set(Key.DEVICE_TOKEN, token)
        settings.deviceChoice = choice
        _state.update { it.copy(device = choice) }
    }

    private fun forgetDevice() {
        secrets.set(Key.DEVICE_TOKEN, null)
        settings.deviceChoice = null
    }

    private fun storedTokens(): TokenPair? {
        val token = secrets.get(Key.ACCESS_TOKEN) ?: return null
        val refreshToken = secrets.get(Key.REFRESH_TOKEN) ?: return null
        return TokenPair(token, refreshToken)
    }

    private fun createClient(address: ServerAddress, tokens: TokenPair?) =
        OptiCloudClient(address, tokens, onTokensChanged = ::storeTokens)

    private fun storeTokens(tokens: TokenPair?) {
        secrets.set(Key.ACCESS_TOKEN, tokens?.token)
        secrets.set(Key.REFRESH_TOKEN, tokens?.refreshToken)
        // The client never reports during its construction, so the state exists by now.
        _state.update { it.copy(signedIn = tokens != null) }
    }
}

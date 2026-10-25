package com.optimeas.opticloudsensor.signin

import androidx.annotation.StringRes
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.optimeas.opticloudsensor.R
import com.optimeas.opticloudsensor.core.api.BINDING_ATTRIBUTE
import com.optimeas.opticloudsensor.core.api.Binding
import com.optimeas.opticloudsensor.core.api.Device
import com.optimeas.opticloudsensor.core.api.DeviceCredentials
import com.optimeas.opticloudsensor.core.api.LoginResult
import com.optimeas.opticloudsensor.core.api.OptiCloudException
import com.optimeas.opticloudsensor.core.api.Project
import com.optimeas.opticloudsensor.core.api.Role
import com.optimeas.opticloudsensor.core.api.ServerAddress
import com.optimeas.opticloudsensor.storage.AppModel
import com.optimeas.opticloudsensor.storage.DeviceChoice
import com.optimeas.opticloudsensor.storage.Named
import java.io.IOException
import javax.net.ssl.SSLException
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** A message for the user, with the server's message as a detail for support. */
data class UserMessage(@param:StringRes val text: Int, val detail: String? = null)

/** A device in the list, with its binding to a phone. */
data class DeviceRow(val device: Device, val binding: Binding)

/** The steps of sign-in and device selection (see `docs/spec/sign-in.md`, Overview). */
sealed interface Step {
    data object Credentials : Step

    data class Tenants(val roles: List<Role>) : Step

    data class Code(val role: Role, val twoFactorToken: String, val email: String) : Step

    /** The project tree, flattened depth first with the depth of each project; [current] is the session's project. */
    data class Projects(val projects: List<Pair<Project, Int>>, val current: String?) : Step

    data class Devices(val rows: List<DeviceRow>, val search: String = "") : Step
}

data class SignInState(
    /** Whether the flow is shown. It ends when a device is chosen or the user leaves it. */
    val active: Boolean = false,
    val step: Step = Step.Credentials,
    val busy: Boolean = false,
    val message: UserMessage? = null,
    /** A device bound to another phone that the user wants to take over; asks for confirmation. */
    val takeOverCandidate: DeviceRow? = null,
)

/**
 * Leads through sign-in and device selection (see `docs/spec/sign-in.md`). The password stays in memory only
 * until sign-in with the role is finished.
 */
class SignInViewModel(private val app: AppModel) : ViewModel() {
    private val _state = MutableStateFlow(SignInState(active = app.state.value.device == null))
    val state: StateFlow<SignInState> = _state.asStateFlow()

    private var email = ""
    private var password: String? = null
    private var tenant: Named? = null
    private var project: Named? = null
    private var projectCount = 0

    private val client get() = app.client

    /** Starts the flow: at the projects when the user is still signed in, otherwise at the credentials. */
    fun start() {
        _state.value = SignInState(active = true)
        if (client.isSignedIn) step { loadProjects() }
    }

    fun signIn(addressText: String, email: String, password: String) = step {
        val address = ServerAddress.parse(addressText) ?: run {
            show(UserMessage(R.string.error_address))
            return@step
        }
        app.changeAddress(address)
        this.email = email.trim()
        this.password = password
        val roles = client.roles(this.email, password).filter { it.enabled }
        when (roles.size) {
            0 -> show(UserMessage(R.string.error_no_tenant))
            1 -> login(roles.single())
            else -> go(Step.Tenants(roles.sortedBy { it.tenant.name.lowercase() }))
        }
    }

    fun chooseTenant(role: Role) = step { login(role) }

    fun submitCode(code: String) = step {
        val current = _state.value.step as? Step.Code ?: return@step
        client.verify(current.twoFactorToken, code.trim())
        signedIn(current.role)
    }

    /** Asks the server for a new code by signing in with the role again; there is no other request for it. */
    fun resendCode() = step {
        val current = _state.value.step as? Step.Code ?: return@step
        login(current.role)
    }

    fun chooseProject(chosen: Project) = step { enterProject(chosen) }

    fun search(text: String) = step { loadDevices(text) }

    fun refreshDevices() = step { loadDevices((_state.value.step as? Step.Devices)?.search ?: "") }

    /** Picks a device. A device bound to another phone is taken over only after confirmation. */
    fun choose(row: DeviceRow, takeOver: Boolean = false) {
        if (row.binding == Binding.OTHER_PHONE && !takeOver) {
            _state.update { it.copy(takeOverCandidate = row) }
            return
        }
        _state.update { it.copy(takeOverCandidate = null) }
        step {
            if (row.binding != Binding.THIS_PHONE) bind(row.device.id)
            finish(row.device)
        }
    }

    fun cancelTakeOver() = _state.update { it.copy(takeOverCandidate = null) }

    fun createDevice(name: String) = step {
        val device = client.createDevice(name.trim())
        bind(device.id)
        finish(device)
    }

    fun dismissMessage() = _state.update { it.copy(message = null) }

    /** One step back. From the devices to the projects if there was a choice; otherwise the flow ends. */
    fun back() {
        val current = _state.value.step
        when {
            current is Step.Devices && projectCount > 1 -> step { loadProjects() }
            current is Step.Tenants || current is Step.Code -> go(Step.Credentials)
            else -> _state.value = SignInState(active = app.state.value.device == null)
        }
    }

    // Steps

    private suspend fun login(role: Role) {
        val password = password ?: return go(Step.Credentials)
        when (val result = client.login(email, password, role.authorityId)) {
            is LoginResult.SignedIn -> signedIn(role)
            is LoginResult.CodeRequired -> go(Step.Code(role, result.twoFactorToken, result.email))
        }
    }

    private suspend fun signedIn(role: Role) {
        password = null
        tenant = Named(role.tenant.id, role.tenant.name)
        loadProjects()
    }

    private suspend fun loadProjects() {
        val flattened = client.projects().flatMap { it.flattened() }
        projectCount = flattened.size
        when (flattened.size) {
            0 -> show(UserMessage(R.string.error_permission_projects))
            1 -> enterProject(flattened.single().first)
            else -> go(Step.Projects(flattened, client.claims?.projectId))
        }
    }

    private suspend fun enterProject(chosen: Project) {
        if (chosen.id != client.claims?.projectId) client.selectProject(chosen.id)
        project = Named(chosen.id, chosen.name)
        loadDevices("")
    }

    private suspend fun loadDevices(search: String) {
        val claims = client.claims ?: throw OptiCloudException.NotSignedIn()
        val tenantId = claims.tenantId ?: throw OptiCloudException.UnexpectedAnswer()
        val projectId = claims.projectId ?: throw OptiCloudException.UnexpectedAnswer()
        val devices = client.devices(tenantId, projectId, search.trim()).filter { it.isSensorAppDevice }
        val rows = coroutineScope {
            devices.map { device ->
                async { DeviceRow(device, Binding.of(client.sharedAttributes(device.id), app.installationId)) }
            }.awaitAll()
        }
        go(Step.Devices(rows.sortedBy { it.device.name.lowercase() }, search))
    }

    private suspend fun bind(deviceId: String) {
        client.setSharedAttributes(deviceId, JsonObject(mapOf(BINDING_ATTRIBUTE to JsonPrimitive(app.installationId))))
    }

    private suspend fun finish(device: Device) {
        val credentials = client.credentials(device.id)
        val token = credentials.credentialsId
        when {
            credentials.credentialsType != DeviceCredentials.ACCESS_TOKEN || token.isNullOrEmpty() ->
                show(UserMessage(R.string.error_not_access_token))
            credentials.enabled == false -> show(UserMessage(R.string.error_device_blocked))
            else -> {
                val claims = client.claims
                val tenant = tenant ?: app.state.value.device?.tenant ?: Named(claims?.tenantId ?: "", "")
                val project = project ?: Named(claims?.projectId ?: "", "")
                app.setDevice(DeviceChoice(tenant, project, Named(device.id, device.name)), token)
                _state.value = SignInState(active = false)
            }
        }
    }

    private fun go(step: Step) = _state.update { it.copy(step = step, message = null) }

    private fun show(message: UserMessage) = _state.update { it.copy(message = message) }

    /** Runs a step in the background, shows that it is busy, and turns errors into a message. */
    private fun step(block: suspend () -> Unit) {
        viewModelScope.launch {
            _state.update { it.copy(busy = true, message = null) }
            try {
                block()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                show(messageFor(e))
            } finally {
                _state.update { it.copy(busy = false) }
            }
        }
    }

    /** What the app says about an error (see `docs/spec/sign-in.md`, Errors). */
    private fun messageFor(e: Exception): UserMessage = when (e) {
        is SSLException -> UserMessage(R.string.error_certificate, e.message)
        is IOException -> UserMessage(R.string.error_network, e.message)
        is OptiCloudException.NotSignedIn -> sessionExpired(null)
        is OptiCloudException.UnexpectedAnswer -> UserMessage(R.string.error_unexpected)
        is OptiCloudException.Api -> {
            // For support: which request failed, and what the server said.
            val detail = "HTTP ${e.status}, ${e.path}" + (e.errorCode?.let { ", errorCode $it" } ?: "") +
                (e.serverMessage?.let { ": $it" } ?: "")
            when (e.errorCode) {
                OptiCloudException.Code.SIGN_IN_FAILED -> {
                    go(Step.Credentials)
                    UserMessage(R.string.error_sign_in_failed, detail)
                }
                // The client has already renewed the session once; it is over.
                OptiCloudException.Code.TOKEN_EXPIRED -> sessionExpired(detail)
                OptiCloudException.Code.ACCOUNT_EXPIRED -> UserMessage(R.string.error_account_expired, detail)
                OptiCloudException.Code.LICENSE_LIMIT -> UserMessage(R.string.error_license_limit, detail)
                OptiCloudException.Code.PERMISSION_MISSING -> UserMessage(permissionMessage(), detail)
                OptiCloudException.Code.INVALID_REQUEST -> UserMessage(invalidMessage(), detail)
                OptiCloudException.Code.TOO_MANY_ATTEMPTS -> UserMessage(R.string.error_too_many_attempts, detail)
                else -> UserMessage(R.string.error_server, detail)
            }
        }
        else -> UserMessage(R.string.error_unexpected, e.message)
    }

    private fun sessionExpired(detail: String?): UserMessage {
        app.signOut()
        go(Step.Credentials)
        return UserMessage(R.string.error_session_expired, detail)
    }

    /** Names the step that failed for lack of a permission. */
    private fun permissionMessage(): Int = when (_state.value.step) {
        is Step.Devices -> R.string.error_permission_device
        is Step.Projects -> R.string.error_permission_projects
        else -> R.string.error_permission
    }

    private fun invalidMessage(): Int =
        if (_state.value.step is Step.Devices) R.string.error_device_name else R.string.error_invalid
}

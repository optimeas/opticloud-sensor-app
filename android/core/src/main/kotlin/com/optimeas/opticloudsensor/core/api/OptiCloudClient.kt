package com.optimeas.opticloudsensor.core.api

import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.DeserializationStrategy
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** Errors of the REST interface. */
sealed class OptiCloudException(message: String) : Exception(message) {
    /** The server answered with an error. [errorCode] decides what the app does (see `docs/spec/sign-in.md`, Errors). */
    class Api(val status: Int, val errorCode: Int?, val serverMessage: String?, val path: String) :
        OptiCloudException("HTTP $status at $path, errorCode $errorCode: $serverMessage")

    /** The answer did not have the expected form. */
    class UnexpectedAnswer : OptiCloudException("unexpected answer")

    /** The request needs a signed-in user. */
    class NotSignedIn : OptiCloudException("not signed in")

    /** The error codes the app distinguishes. */
    object Code {
        const val SIGN_IN_FAILED = 10
        const val TOKEN_EXPIRED = 11
        const val ACCOUNT_EXPIRED = 12
        const val LICENSE_LIMIT = 14
        const val PERMISSION_MISSING = 20
        const val INVALID_REQUEST = 31
        const val TOO_MANY_ATTEMPTS = 33
    }
}

/** The `errorCode` of the server, if this is an error answer of the REST interface. */
val Throwable.errorCode: Int? get() = (this as? OptiCloudException.Api)?.errorCode

/**
 * The REST interface of optiCLOUD for sign-in, projects, devices, and their binding (see `docs/spec/sign-in.md`).
 *
 * The client keeps the user's tokens. It renews the session when the access token expires within
 * [RENEWAL_MARGIN_SECONDS] and, when the server reports an expired token, renews it and repeats the request once.
 * [onTokensChanged] is called whenever the tokens change, so that the app can store them; null means signed out.
 */
class OptiCloudClient(
    val address: ServerAddress,
    tokens: TokenPair? = null,
    private val transport: HttpTransport = UrlConnectionTransport(),
    private val nowMillis: () -> Long = System::currentTimeMillis,
    private val onTokensChanged: (TokenPair?) -> Unit = {},
) {
    @Volatile
    var tokens: TokenPair? = tokens
        private set

    private val renewal = Mutex()

    val isSignedIn: Boolean get() = tokens != null

    /** The claims of the current access token. */
    val claims: AccessTokenClaims? get() = tokens?.let { runCatching { AccessTokenClaims.parse(it.token) }.getOrNull() }

    /** Forgets the tokens. The server does not invalidate them. */
    fun signOut() = setTokens(null)

    // Sign-in

    /** The user's roles, one per tenant. Issues no token. */
    suspend fun roles(username: String, password: String): List<Role> = try {
        send("POST", "/api/noauth/authorization", ListSerializer(Role.serializer()), body = obj("username" to username, "password" to password))
    } catch (e: OptiCloudException.Api) {
        // An unknown e-mail address is answered with status 400 and no errorCode.
        if (e.status != 400 || e.errorCode != null) throw e
        throw OptiCloudException.Api(e.status, OptiCloudException.Code.SIGN_IN_FAILED, e.serverMessage, e.path)
    }

    /** Signs in with a role. If the server requires a code, confirm it with [verify]. */
    suspend fun login(username: String, password: String, authorityId: String): LoginResult {
        val result = send(
            "POST", "/api/auth/login", LoginResponse.serializer(),
            body = obj("username" to username, "password" to password, "authorityId" to authorityId),
        ).result()
        if (result is LoginResult.SignedIn) setTokens(result.tokens)
        return result
    }

    /** Confirms the code sent by e-mail. */
    suspend fun verify(twoFactorToken: String, code: String) {
        setTokens(send("POST", "/api/noauth/2fa/verify", LoginResponse.serializer(), body = obj("twoFactorToken" to twoFactorToken, "code" to code)).tokens())
    }

    /** Renews the session. A call that waited while another one renewed takes over its result. */
    suspend fun renew(): TokenPair {
        val before = tokens
        return renewal.withLock {
            val current = tokens ?: throw OptiCloudException.NotSignedIn()
            if (current !== before) return@withLock current
            send("POST", "/api/auth/token", LoginResponse.serializer(), body = obj("refreshToken" to current.refreshToken))
                .tokens()
                .also(::setTokens)
        }
    }

    // Projects

    /** The project tree of the role. */
    suspend fun projects(): List<Project> = authorized("GET", "/api/projects/enabled", ListSerializer(Project.serializer()))

    /** Moves the session into another project. The answer is a new token pair. */
    suspend fun selectProject(projectId: String) {
        setTokens(authorized("POST", "/api/auth/selectProject/$projectId", LoginResponse.serializer()).tokens())
    }

    // Devices

    /** All devices of the project of the session, of every type. Keep those with [Device.isSensorAppDevice]. */
    suspend fun devices(tenantId: String, projectId: String, textSearch: String? = null): List<Device> {
        val devices = mutableListOf<Device>()
        var page = 0
        while (true) {
            val query = buildList {
                add("projectId" to projectId)
                add("limit" to PAGE_SIZE.toString())
                add("page" to page.toString())
                if (!textSearch.isNullOrEmpty()) add("textSearch" to textSearch)
            }
            val result = authorized("GET", "/api/tenants/$tenantId/devices", Page.serializer(Device.serializer()), query)
            devices += result.data
            if (!result.hasNext) return devices
            page++
        }
    }

    /** Creates a device of the app in the project of the session. */
    suspend fun createDevice(name: String): Device =
        authorized("POST", "/api/devices", Device.serializer(), body = obj("name" to name, "type" to DEVICE_TYPE))

    suspend fun credentials(deviceId: String): DeviceCredentials =
        authorized("GET", "/api/device/$deviceId/credentials", DeviceCredentials.serializer())

    // Attributes

    suspend fun sharedAttributes(deviceId: String): List<AttributeEntry> =
        authorized("GET", "/api/plugins/telemetry/DEVICE/$deviceId/values/attributes/SHARED_SCOPE", ListSerializer(AttributeEntry.serializer()))

    suspend fun setSharedAttributes(deviceId: String, attributes: JsonObject) {
        authorized<Unit>("POST", "/api/plugins/telemetry/DEVICE/$deviceId/attributes/SHARED_SCOPE", null, body = attributes)
    }

    // Requests

    private fun setTokens(pair: TokenPair?) {
        tokens = pair
        onTokensChanged(pair)
    }

    /** Sends a request with the user's access token. */
    private suspend fun <T> authorized(
        method: String,
        path: String,
        answer: DeserializationStrategy<T>?,
        query: List<Pair<String, String>> = emptyList(),
        body: JsonElement? = null,
    ): T {
        if (tokens == null) throw OptiCloudException.NotSignedIn()
        val exp = claims?.exp
        if (exp != null && exp * 1000 - nowMillis() < RENEWAL_MARGIN_SECONDS * 1000) renew()
        return try {
            send(method, path, answer, query, body, tokens?.token)
        } catch (e: OptiCloudException.Api) {
            if (e.errorCode != OptiCloudException.Code.TOKEN_EXPIRED) throw e
            renew()
            send(method, path, answer, query, body, tokens?.token)
        }
    }

    /** With [answer] null the answer is not read, and the function returns `Unit`. */
    @Suppress("UNCHECKED_CAST")
    private suspend fun <T> send(
        method: String,
        path: String,
        answer: DeserializationStrategy<T>?,
        query: List<Pair<String, String>> = emptyList(),
        body: JsonElement? = null,
        token: String? = null,
    ): T {
        val headers = buildMap {
            put("Accept", "application/json")
            if (token != null) put("X-Authorization", "Bearer $token")
            if (body != null) put("Content-Type", "application/json")
        }
        val response = transport.send(HttpRequest(method, address.url(path, query), headers, body?.toString()?.toByteArray()))
        val text = response.body.toString(Charsets.UTF_8)
        if (response.status !in 200..299) {
            val error = runCatching { json.decodeFromString(ApiErrorBody.serializer(), text) }.getOrNull()
            throw OptiCloudException.Api(response.status, error?.errorCode, error?.message, path)
        }
        if (answer == null) return Unit as T
        return try {
            json.decodeFromString(answer, text)
        } catch (_: Exception) {
            throw OptiCloudException.UnexpectedAnswer()
        }
    }

    private fun obj(vararg members: Pair<String, String>) = JsonObject(members.associate { (key, value) -> key to JsonPrimitive(value) })

    companion object {
        /** Renew the session when the access token expires within this time. */
        const val RENEWAL_MARGIN_SECONDS = 120L

        private const val PAGE_SIZE = 100

        private val json = Json { ignoreUnknownKeys = true }
    }
}

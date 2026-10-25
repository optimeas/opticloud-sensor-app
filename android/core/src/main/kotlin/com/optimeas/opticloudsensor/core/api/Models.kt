package com.optimeas.opticloudsensor.core.api

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonPrimitive

/** The device type of devices the app uses (see `docs/spec/sign-in.md`, Marking devices of the app). */
const val DEVICE_TYPE = "optiCLOUD Sensor App"

/** The shared attribute that binds a device to one phone (see `docs/spec/sign-in.md`, Binding to the phone). */
const val BINDING_ATTRIBUTE = "sensorAppInstallation"

/**
 * Reads an identifier written as an object with `id`, such as `{ "entityType": "DEVICE", "id": "…" }`,
 * or as a plain string (see `docs/spec/sign-in.md`).
 */
object EntityIdSerializer : KSerializer<String> {
    override val descriptor = PrimitiveSerialDescriptor("EntityId", PrimitiveKind.STRING)

    override fun deserialize(decoder: Decoder): String {
        val element = (decoder as JsonDecoder).decodeJsonElement()
        val id = when (element) {
            is JsonPrimitive -> element.takeIf { it.isString }
            is JsonObject -> element["id"] as? JsonPrimitive
            else -> null
        }
        return id?.content ?: throw SerializationException("not an identifier: $element")
    }

    override fun serialize(encoder: Encoder, value: String) = encoder.encodeString(value)
}

/** A role of the user. Each role belongs to one tenant (see `docs/spec/sign-in.md`, Tenants). */
@Serializable
data class Role(
    @Serializable(EntityIdSerializer::class) val authorityId: String,
    val authority: String? = null,
    val tenant: Tenant,
    val enabled: Boolean = false,
    val projectCount: Int? = null,
) {
    @Serializable
    data class Tenant(@Serializable(EntityIdSerializer::class) val id: String, val name: String)
}

/** The access token and the refresh token of the user's session. */
data class TokenPair(val token: String, val refreshToken: String)

/** The answer to signing in with a role. */
sealed interface LoginResult {
    data class SignedIn(val tokens: TokenPair) : LoginResult

    /** The server has sent a code to [email]; confirm it with [twoFactorToken]. */
    data class CodeRequired(val twoFactorToken: String, val email: String) : LoginResult
}

@Serializable
internal data class LoginResponse(
    val token: String? = null,
    val refreshToken: String? = null,
    val twoFactorRequired: Boolean? = null,
    val twoFactorToken: String? = null,
    val twoFactorEmail: String? = null,
) {
    fun result(): LoginResult =
        if (twoFactorRequired == true) {
            LoginResult.CodeRequired(twoFactorToken ?: throw OptiCloudException.UnexpectedAnswer(), twoFactorEmail ?: "")
        } else {
            LoginResult.SignedIn(tokens())
        }

    fun tokens(): TokenPair =
        TokenPair(token ?: throw OptiCloudException.UnexpectedAnswer(), refreshToken ?: throw OptiCloudException.UnexpectedAnswer())
}

/** A project in the project tree of a tenant. */
@Serializable
data class Project(
    @Serializable(EntityIdSerializer::class) val id: String,
    val name: String,
    val children: List<Project> = emptyList(),
) {
    /** This project and all projects below it, depth first, each with its depth in the tree. */
    fun flattened(depth: Int = 0): List<Pair<Project, Int>> =
        listOf(this to depth) + children.flatMap { it.flattened(depth + 1) }
}

/** A device in optiCLOUD. */
@Serializable
data class Device(
    @Serializable(EntityIdSerializer::class) val id: String,
    val name: String,
    val type: String? = null,
    val label: String? = null,
) {
    /** Whether the device is one of the app. */
    val isSensorAppDevice: Boolean get() = type == DEVICE_TYPE
}

@Serializable
internal data class Page<T>(val data: List<T>, val hasNext: Boolean = false)

/** The credentials of a device (see `docs/spec/sign-in.md`, Reading the access token). */
@Serializable
data class DeviceCredentials(val credentialsType: String, val credentialsId: String? = null, val enabled: Boolean? = null) {
    companion object {
        const val ACCESS_TOKEN = "ACCESS_TOKEN"
    }
}

/** One attribute as the REST interface lists it. */
@Serializable
data class AttributeEntry(val key: String, val value: JsonElement, val lastUpdateTs: Long? = null)

/** The binding of a device to a phone, read from its shared attributes. */
enum class Binding {
    THIS_PHONE,
    OTHER_PHONE,
    NONE,
    ;

    companion object {
        fun of(attributes: List<AttributeEntry>, installationId: String): Binding {
            val value = attributes.firstOrNull { it.key == BINDING_ATTRIBUTE }?.value
            return when {
                value == null || value is kotlinx.serialization.json.JsonNull -> NONE
                value is JsonPrimitive && value.isString && value.content == installationId -> THIS_PHONE
                else -> OTHER_PHONE
            }
        }
    }
}

/**
 * The error body of the REST interface (see `docs/spec/sign-in.md`, Errors). Its `status` is left out: some
 * answers write it as a name such as `UNAUTHORIZED`; the status comes from the HTTP response.
 */
@Serializable
data class ApiErrorBody(val message: String? = null, val errorCode: Int? = null)

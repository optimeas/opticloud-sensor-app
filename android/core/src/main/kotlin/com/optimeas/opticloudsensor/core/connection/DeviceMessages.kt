package com.optimeas.opticloudsensor.core.connection

import com.optimeas.opticloudsensor.core.JsonCodec
import com.optimeas.opticloudsensor.core.TelemetryValue
import com.optimeas.opticloudsensor.core.api.BINDING_ATTRIBUTE
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** Topics and payloads of attributes and commands (see `docs/spec/messages.md`). */
object DeviceMessages {
    const val ATTRIBUTES = "v2/json/devices/me/attributes"
    const val ATTRIBUTE_REQUEST_PREFIX = "v2/json/devices/me/attributes/request/"
    const val ATTRIBUTE_RESPONSE_PREFIX = "v2/json/devices/me/attributes/response/"
    const val RPC_REQUEST_PREFIX = "v2/json/devices/me/rpc/request/"
    const val RPC_RESPONSE_PREFIX = "v2/json/devices/me/rpc/response/"

    /** The topic filters the app subscribes to after every connect (see `docs/spec/connection.md`, Subscriptions). */
    val SUBSCRIPTIONS = listOf(ATTRIBUTES, ATTRIBUTE_RESPONSE_PREFIX + "+", RPC_REQUEST_PREFIX + "+")

    /** The shared attributes the app requests after every connect. */
    val REQUESTED_SHARED_KEYS = listOf("sendRate", "sensors", "dashboard", BINDING_ATTRIBUTE)

    /** An attribute request expires after this time; the request has then failed. */
    const val REQUEST_TIMEOUT_MILLIS = 10_000L

    private val json = Json { ignoreUnknownKeys = true }

    fun attributeRequest(sharedKeys: List<String>): String =
        JsonCodec.compact(JsonObject(mapOf("sharedKeys" to JsonPrimitive(sharedKeys.joinToString(",")))))

    /** The client attributes as one flat object. Values that cannot be sent are left out. */
    fun clientAttributes(attributes: Map<String, TelemetryValue>): String =
        JsonCodec.compact(JsonObject(attributes.filterValues { it.isSendable }.mapValues { (_, value) -> JsonCodec.encode(value) }))

    /** The identifier at the end of a topic, such as the `5` in `…/rpc/request/5`; null if it is not a positive number. */
    fun requestId(topic: String, prefix: String): Long? =
        topic.takeIf { it.startsWith(prefix) }?.removePrefix(prefix)?.toLongOrNull()?.takeIf { it > 0 }

    /**
     * The shared attributes of a change (`{ "shared": { … } }`) or of an answer to a request
     * (`{ "client": { … }, "shared": { … } }`). A key with the value `null` was deleted. Null if the payload
     * cannot be read.
     */
    fun sharedAttributes(payload: String): Map<String, JsonElement>? {
        val root = runCatching { json.parseToJsonElement(payload) }.getOrNull() as? JsonObject ?: return null
        return when (val shared = root["shared"]) {
            null -> emptyMap()
            is JsonObject -> shared
            else -> null
        }
    }

    /** A command from the server (see `docs/spec/messages.md`, Commands). */
    data class Command(val method: String, val params: JsonElement)

    fun command(payload: String): Command? {
        val root = runCatching { json.parseToJsonElement(payload) }.getOrNull() as? JsonObject ?: return null
        val method = (root["method"] as? JsonPrimitive)?.takeIf { it.isString }?.content ?: return null
        return Command(method, root["params"] ?: JsonNull)
    }
}

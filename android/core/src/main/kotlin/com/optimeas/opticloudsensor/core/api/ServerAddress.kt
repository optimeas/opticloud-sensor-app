package com.optimeas.opticloudsensor.core.api

import java.net.URI
import java.net.URLEncoder

/**
 * The address of the optiCLOUD web application, such as `https://dashboard.opticloud.io`
 * (see `docs/spec/connection.md`, Endpoint). Only scheme, host, and port are kept.
 */
class ServerAddress private constructor(val host: String, val port: Int?) {
    /** The address as the user sees it. */
    val text: String get() = "https://$host" + (port?.let { ":$it" } ?: "")

    /** The host of the MQTT endpoint: the same host name. */
    val mqttHost: String get() = host

    /** The URL of a path of the REST interface, such as `/api/auth/login`, with an optional query. */
    fun url(path: String, query: List<Pair<String, String>> = emptyList()): String {
        val encoded = query.joinToString("&") { (name, value) -> "${encode(name)}=${encode(value)}" }
        return text + path + if (encoded.isEmpty()) "" else "?$encoded"
    }

    override fun equals(other: Any?) = other is ServerAddress && other.text == text

    override fun hashCode() = text.hashCode()

    override fun toString() = text

    companion object {
        /** The MQTT port by convention of optiCLOUD installations. */
        const val MQTT_PORT = 8883

        /** The official optiCLOUD server of optiMEAS, the default address. */
        val OFFICIAL: ServerAddress = parse("https://dashboard.opticloud.io")!!

        /**
         * Accepts an address that starts with `https://` and has a host name. Path, query, and a trailing
         * slash are dropped. Returns null for anything else.
         */
        fun parse(text: String): ServerAddress? {
            val trimmed = text.trim()
            if (!trimmed.lowercase().startsWith("https://")) return null
            val uri = try {
                URI(trimmed)
            } catch (_: Exception) {
                return null
            }
            val host = uri.host?.lowercase()?.takeIf { it.isNotEmpty() } ?: return null
            return ServerAddress(host, uri.port.takeIf { it != -1 })
        }

        private fun encode(text: String) = URLEncoder.encode(text, Charsets.UTF_8).replace("+", "%20")
    }
}

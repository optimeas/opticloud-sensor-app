package com.optimeas.opticloudsensor.core.connection

/**
 * Where and as whom the app connects (see `docs/spec/connection.md`, Signing on as a device). [token] is the
 * device access token; it is never shown and never logged.
 */
class MqttEndpoint(val host: String, val port: Int, val clientId: String, val token: String) {
    override fun toString() = "MqttEndpoint($host:$port)"
}

/** Why an attempt to connect failed or an open connection ended. */
class MqttFailure(val kind: Kind, cause: Throwable? = null) : Exception(kind.name, cause) {
    enum class Kind {
        /** The server answered "bad user name or password": no token was sent. */
        BAD_CREDENTIALS,

        /** The server answered "not authorized": the token is unknown or disabled, or the tenant has expired. */
        NOT_AUTHORIZED,

        /** The server answered "server unavailable". */
        SERVER_UNAVAILABLE,

        /** The server could not be reached. */
        UNREACHABLE,

        /** The certificate of the server is not trusted. */
        CERTIFICATE,

        /** The server refused a subscription. */
        SUBSCRIPTION_REFUSED,

        /** An open connection was lost or closed by the server. */
        LOST,
    }
}

/** One open MQTT connection. Every call throws [MqttFailure] when the connection is lost. */
interface MqttSession {
    /** Subscribes with QoS 1 and returns when the server has confirmed every filter. */
    suspend fun subscribe(filters: List<String>)

    /** Publishes with QoS 1 and returns when the server has acknowledged the message. */
    suspend fun publish(topic: String, payload: String)

    /** Returns when the connection has ended, with the reason. */
    suspend fun awaitClosed(): MqttFailure

    /** Sends DISCONNECT if the connection is still open. */
    suspend fun disconnect()
}

/** Opens MQTT connections. The app implements it with the HiveMQ MQTT Client. */
fun interface MqttConnector {
    /**
     * Connects and signs on, and returns once the server has accepted. [onMessage] receives every message the
     * server sends on this connection, as topic and UTF-8 text. Throws [MqttFailure] if the attempt fails.
     */
    suspend fun connect(endpoint: MqttEndpoint, onMessage: (topic: String, payload: String) -> Unit): MqttSession
}

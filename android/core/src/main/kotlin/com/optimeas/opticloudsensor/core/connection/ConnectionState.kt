package com.optimeas.opticloudsensor.core.connection

import kotlin.math.min

/** Why the app is waiting or refused (see `docs/spec/connection.md`, States). */
enum class ConnectionReason {
    NO_NETWORK,
    SERVER_NOT_REACHABLE,
    CERTIFICATE_NOT_TRUSTED,
    CONNECTION_LOST,
    TOKEN_REFUSED,
    BOUND_TO_ANOTHER_PHONE,
    NOT_BOUND,
}

/** The connection state (see `docs/spec/connection.md`, Connection). [since] is when the state began, in milliseconds. */
sealed interface ConnectionState {
    data object Disconnected : ConnectionState

    data object Connecting : ConnectionState

    data object Connected : ConnectionState

    /** The connection was lost or failed; the next attempt is at [retryAt], or when the network is back. */
    data class Waiting(val reason: ConnectionReason, val since: Long, val retryAt: Long?) : ConnectionState

    /** The server refused the token, or the device belongs to another phone. The app does not retry. */
    data class Refused(val reason: ConnectionReason, val since: Long) : ConnectionState
}

/** The delay before the next attempt to connect (see `docs/spec/connection.md`, Reconnecting). */
object ReconnectDelay {
    const val FIRST_MILLIS = 1_000L
    const val MAX_MILLIS = 60_000L

    /** Up to 20 percent up or down. */
    const val JITTER = 0.2

    /**
     * The delay after [failures] failed attempts in a row (1 for the first failure): 1 s, doubling up to 60 s.
     * [random] in [0, 1) varies it by up to 20 percent in both directions.
     */
    fun millis(failures: Int, random: Double): Long {
        val base = min(MAX_MILLIS, FIRST_MILLIS shl min(failures - 1, 16).coerceAtLeast(0))
        return (base * (1 + JITTER * (2 * random - 1))).toLong()
    }
}

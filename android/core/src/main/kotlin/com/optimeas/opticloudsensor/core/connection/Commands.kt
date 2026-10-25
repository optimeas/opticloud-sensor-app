package com.optimeas.opticloudsensor.core.connection

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * The result of a command: the answer to publish, the settings afterwards, and whether the app must take one
 * sample at once.
 */
data class CommandResult(val answer: JsonObject, val settings: DeviceSettings, val sendNow: Boolean = false)

/** Carries out commands from the server (see `docs/spec/messages.md`, Commands). */
object Commands {
    const val UNKNOWN_METHOD = "unknown method"
    const val INVALID_PARAMS = "invalid params"
    const val MANAGED_SETTING = "managed setting"

    /** [reportedSensors] is the selection as the app reports it, such as `device,location`. */
    fun carryOut(command: DeviceMessages.Command, settings: DeviceSettings, reportedSensors: String): CommandResult {
        fun answer(vararg members: Pair<String, JsonPrimitive>) = JsonObject(members.toMap())
        fun error(text: String) = CommandResult(answer("error" to JsonPrimitive(text)), settings)

        return when (command.method) {
            "ping" -> CommandResult(answer("pong" to JsonPrimitive(true)), settings)
            "getState" -> CommandResult(
                answer(
                    "transmitting" to JsonPrimitive(settings.transmitting),
                    "sendRate" to JsonPrimitive(settings.sendRate),
                    "sensors" to JsonPrimitive(reportedSensors),
                ),
                settings,
            )
            "startTransmission" -> CommandResult(answer("transmitting" to JsonPrimitive(true)), settings.copy(transmitting = true))
            "stopTransmission" -> CommandResult(answer("transmitting" to JsonPrimitive(false)), settings.copy(transmitting = false))
            "setSendRate" -> {
                val seconds = SharedAttributes.sendRate((command.params as? JsonObject)?.get("seconds"))
                when {
                    "sendRate" in settings.managed -> error(MANAGED_SETTING)
                    seconds == null -> error(INVALID_PARAMS)
                    else -> CommandResult(answer("sendRate" to JsonPrimitive(seconds)), settings.copy(sendRate = seconds))
                }
            }
            "sendNow" -> CommandResult(answer("sent" to JsonPrimitive(true)), settings, sendNow = true)
            else -> error(UNKNOWN_METHOD)
        }
    }
}

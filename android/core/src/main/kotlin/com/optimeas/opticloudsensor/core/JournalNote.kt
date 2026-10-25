package com.optimeas.opticloudsensor.core

import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject

/**
 * A journal entry as the user saved it (see `docs/spec/journal.md`, Entry). [savedAt] is the moment of saving
 * in milliseconds, [utcOffsetMinutes] the offset of the phone's local time from UTC at that moment.
 */
data class JournalEntry(
    val title: String,
    val text: String,
    val status: Status = Status.CREATED,
    val priority: Priority = Priority.MEDIUM,
    val savedAt: Long,
    val utcOffsetMinutes: Int,
    val latitude: Double? = null,
    val longitude: Double? = null,
) {
    enum class Status { CREATED, ARCHIVED }

    enum class Priority { LOW, MEDIUM, HIGH }
}

/** The claims of the user's access token that a note needs (see `docs/spec/sign-in.md`, The session). */
data class SessionClaims(val tenantId: String, val projectId: String, val authorityDataId: String)

/** The request body that creates a note from a journal entry (see `docs/spec/journal.md`, Note). */
object JournalNote {
    const val SOURCE = "optiCLOUD Sensor App"

    private val timeFormat = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm xxx")

    fun body(entry: JournalEntry, claims: SessionClaims, deviceId: String): JsonObject = buildJsonObject {
        putEntityId("entityId", "DEVICE", deviceId)
        putEntityId("tenantId", "TENANT", claims.tenantId)
        putEntityId("projectId", "PROJECT", claims.projectId)
        putEntityId("authorityDataId", "AUTHORITY_DATA", claims.authorityDataId)
        put("name", entry.title)
        put("text", entry.text + "\n\n" + savedAtText(entry.savedAt, entry.utcOffsetMinutes))
        put("status", entry.status.name)
        put("priority", entry.priority.name)
        putJsonObject("additionalInfo") {
            put("source", SOURCE)
            put("savedAt", JsonPrimitive(entry.savedAt))
            entry.latitude?.let { put("latitude", JsonCodec.number(it)) }
            entry.longitude?.let { put("longitude", JsonCodec.number(it)) }
        }
    }

    /** The moment of saving in local time with its offset from UTC, such as `2026-10-24 15:42 +02:00`. */
    fun savedAtText(savedAt: Long, utcOffsetMinutes: Int): String =
        Instant.ofEpochMilli(savedAt).atOffset(ZoneOffset.ofTotalSeconds(utcOffsetMinutes * 60)).format(timeFormat)

    private fun kotlinx.serialization.json.JsonObjectBuilder.putEntityId(key: String, entityType: String, id: String) {
        putJsonObject(key) {
            put("entityType", entityType)
            put("id", id)
        }
    }
}

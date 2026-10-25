package com.optimeas.opticloudsensor.core

import kotlinx.serialization.json.JsonArray

/** Telemetry messages (see `docs/spec/messages.md`, Telemetry, and `docs/spec/offline-queue.md`, Delivering). */
object Telemetry {
    const val TOPIC = "v2/json/devices/me/telemetry"

    /** The largest payload the app sends, in bytes. */
    const val MAX_PAYLOAD_BYTES = 32_768

    /** The payload of one message: the samples as a JSON array, ordered by rising time stamp, without white space. */
    fun payload(samples: List<Sample>): String = JsonCodec.compact(JsonArray(ordered(samples).map(JsonCodec::encode)))

    /** The length of a sample in UTF-8, written as JSON without white space. */
    fun encodedSize(sample: Sample): Int = JsonCodec.compact(JsonCodec.encode(sample)).toByteArray(Charsets.UTF_8).size

    /**
     * Divides the front of the queue into messages, in the order they are sent. A message takes samples until
     * the next one would make its payload larger than [maxPayloadBytes]. A sample that is larger on its own
     * goes into a message of its own.
     */
    fun messages(queue: List<Sample>, maxPayloadBytes: Int = MAX_PAYLOAD_BYTES): List<List<Sample>> {
        val messages = mutableListOf<List<Sample>>()
        var current = mutableListOf<Sample>()
        var size = 2 // the brackets of the array
        for (sample in queue) {
            val sampleSize = encodedSize(sample)
            if (current.isNotEmpty() && size + 1 + sampleSize > maxPayloadBytes) { // 1 for the comma
                messages += ordered(current)
                current = mutableListOf()
                size = 2
            }
            size += sampleSize + if (current.isEmpty()) 0 else 1
            current += sample
        }
        if (current.isNotEmpty()) messages += ordered(current)
        return messages
    }

    /** Samples with the same time stamp keep their order. */
    private fun ordered(samples: List<Sample>): List<Sample> = samples.sortedBy { it.ts }
}

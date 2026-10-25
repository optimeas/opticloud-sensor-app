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
        var rest = queue
        while (rest.isNotEmpty()) {
            val count = firstMessageCount(rest.map(::encodedSize), maxPayloadBytes)
            messages += ordered(rest.take(count))
            rest = rest.drop(count)
        }
        return messages
    }

    /**
     * How many samples from the front of the queue go into the next message, given their encoded sizes: as
     * many as fit into [maxPayloadBytes], and at least one.
     */
    fun firstMessageCount(sizes: List<Int>, maxPayloadBytes: Int = MAX_PAYLOAD_BYTES): Int {
        var size = 2 // the brackets of the array
        for ((index, sampleSize) in sizes.withIndex()) {
            if (index > 0 && size + 1 + sampleSize > maxPayloadBytes) return index // 1 for the comma
            size += sampleSize + if (index == 0) 0 else 1
        }
        return sizes.size
    }

    /** Samples with the same time stamp keep their order. */
    private fun ordered(samples: List<Sample>): List<Sample> = samples.sortedBy { it.ts }
}

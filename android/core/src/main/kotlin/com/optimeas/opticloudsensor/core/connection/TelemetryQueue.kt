package com.optimeas.opticloudsensor.core.connection

import com.optimeas.opticloudsensor.core.JsonCodec
import com.optimeas.opticloudsensor.core.Sample
import com.optimeas.opticloudsensor.core.Telemetry
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** A sample in the queue: its position [id], its time stamp, and its JSON text with the length in UTF-8. */
data class QueuedSample(val id: Long, val ts: Long, val json: String, val size: Int)

/** Samples discarded since the user last reset the count, and the time range they covered. */
data class Discarded(val count: Long = 0, val firstTs: Long? = null, val lastTs: Long? = null) {
    fun plus(samples: List<QueuedSample>): Discarded {
        if (samples.isEmpty()) return this
        val first = samples.minOf { it.ts }
        val last = samples.maxOf { it.ts }
        return Discarded(count + samples.size, minOf(first, firstTs ?: first), maxOf(last, lastTs ?: last))
    }
}

/** Where the queue lives. The app stores it on the phone so that it survives a restart. */
interface QueueStore {
    fun append(ts: Long, json: String, size: Int)

    /** Up to [limit] samples from the front of the queue, oldest first. */
    fun front(limit: Int): List<QueuedSample>

    fun remove(ids: Collection<Long>)

    val count: Long

    /** The sum of the sizes of all samples. */
    val bytes: Long

    val oldestTs: Long?

    var discarded: Discarded

    /** Removes all samples. The discarded count stays. */
    fun clear()
}

/** What the test area shows of the queue (see `docs/spec/offline-queue.md`, Status). */
data class QueueStatus(val count: Long, val bytes: Long, val oldestTs: Long?, val discarded: Discarded)

/** A telemetry message made from the front of the queue. */
class QueueMessage(val samples: List<QueuedSample>) {
    /** The samples ordered by rising time stamp, as one JSON array without white space. */
    val payload: String = samples.sortedBy { it.ts }.joinToString(",", "[", "]") { it.json }
}

/**
 * The offline queue of telemetry (see `docs/spec/offline-queue.md`). Every sample goes through it. At most one
 * message is unacknowledged at a time; the sender takes [next], publishes it, and reports [acknowledged] or
 * [connectionClosed].
 */
class TelemetryQueue(private val store: QueueStore, private val maxBytes: Long = MAX_BYTES) {
    private val _status = MutableStateFlow(readStatus())
    val status: StateFlow<QueueStatus> = _status.asStateFlow()

    private var failedFirstId: Long? = null
    private var failures = 0

    /** Appends a sample. When the queue is full, the oldest samples are discarded until the new one fits. */
    @Synchronized
    fun append(sample: Sample) {
        val json = JsonCodec.compact(JsonCodec.encode(sample))
        val size = json.toByteArray(Charsets.UTF_8).size
        while (store.count > 0 && store.bytes + size > maxBytes) {
            discard(store.front(DISCARD_STEP).takeWhileSum(store.bytes + size - maxBytes))
        }
        store.append(sample.ts, json, size)
        update()
    }

    /** The next message to send, or null if the queue is empty. */
    @Synchronized
    fun next(): QueueMessage? {
        val front = store.front(FRONT_LIMIT)
        if (front.isEmpty()) return null
        return QueueMessage(front.take(Telemetry.firstMessageCount(front.map { it.size })))
    }

    /** The server has acknowledged [message]; its samples leave the queue. */
    @Synchronized
    fun acknowledged(message: QueueMessage) {
        store.remove(message.samples.map { it.id })
        failedFirstId = null
        failures = 0
        update()
    }

    /**
     * The connection closed while [message] was unacknowledged. After the third time in a row for the same
     * message, the app assumes the server cannot read it and discards its samples.
     */
    @Synchronized
    fun connectionClosed(message: QueueMessage) {
        val firstId = message.samples.first().id
        failures = if (firstId == failedFirstId) failures + 1 else 1
        failedFirstId = firstId
        if (failures >= MAX_FAILURES) {
            discard(message.samples)
            failedFirstId = null
            failures = 0
        }
    }

    /** Discards all samples, for example when the user picks another device. They count as discarded. */
    @Synchronized
    fun discardAll() {
        while (store.count > 0) discard(store.front(DISCARD_STEP))
    }

    @Synchronized
    fun resetDiscarded() {
        store.discarded = Discarded()
        update()
    }

    private fun discard(samples: List<QueuedSample>) {
        store.discarded = store.discarded.plus(samples)
        store.remove(samples.map { it.id })
        update()
    }

    private fun update() {
        _status.value = readStatus()
    }

    private fun readStatus() = QueueStatus(store.count, store.bytes, store.oldestTs, store.discarded)

    /** The shortest front whose sizes add up to at least [bytes]. */
    private fun List<QueuedSample>.takeWhileSum(bytes: Long): List<QueuedSample> {
        var sum = 0L
        val taken = mutableListOf<QueuedSample>()
        for (sample in this) {
            if (sum >= bytes) break
            taken += sample
            sum += sample.size
        }
        return taken
    }

    companion object {
        /** 50 MB, counted as the size of the samples in JSON. */
        const val MAX_BYTES = 50_000_000L
        const val MAX_FAILURES = 3

        /** Enough samples to fill a message: a sample takes at least 20 bytes. */
        private const val FRONT_LIMIT = Telemetry.MAX_PAYLOAD_BYTES / 20
        private const val DISCARD_STEP = 1000
    }
}

/** A queue in memory, for tests and as a fallback. */
class MemoryQueueStore : QueueStore {
    private val samples = ArrayDeque<QueuedSample>()
    private var nextId = 1L

    override fun append(ts: Long, json: String, size: Int) {
        samples.addLast(QueuedSample(nextId++, ts, json, size))
    }

    override fun front(limit: Int) = samples.take(limit)

    override fun remove(ids: Collection<Long>) {
        val set = ids.toSet()
        samples.removeAll { it.id in set }
    }

    override val count get() = samples.size.toLong()
    override val bytes get() = samples.sumOf { it.size.toLong() }
    override val oldestTs get() = samples.minOfOrNull { it.ts }
    override var discarded = Discarded()

    override fun clear() = samples.clear()
}

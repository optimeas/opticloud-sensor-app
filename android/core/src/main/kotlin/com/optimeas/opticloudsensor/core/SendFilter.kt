package com.optimeas.opticloudsensor.core

/** The send mode (see `docs/spec/configuration.md`). [key] is how the mode is written. */
enum class SendMode(val key: String) {
    /** Only values that changed since they were last sent, and a full sample every 60 seconds. */
    ON_CHANGE("onChange"),

    /** All selected values at every tick. */
    EVERY_TICK("everyTick"),
    ;

    companion object {
        fun fromKey(key: String): SendMode? = entries.firstOrNull { it.key == key }
    }
}

/**
 * Chooses the values sent at each tick and rounds them (see `docs/spec/sensors.md`, Sending on change).
 *
 * "Sent" means handed to the offline queue. Create a new filter when transmission is switched on.
 */
class SendFilter(var mode: SendMode = SendMode.ON_CHANGE) {
    private val lastSent = mutableMapOf<String, TelemetryValue>()
    private var lastFullSample: Long? = null
    private var fullSampleDue = true

    /** Call when the selection changes. The next tick then sends a full sample. */
    fun selectionChanged() {
        fullSampleDue = true
    }

    /**
     * Returns the sample to send for the values measured at [ts], or null if there is nothing to send.
     * Values that are not available are simply missing from [measured].
     */
    fun sample(ts: Long, measured: Map<String, TelemetryValue>): Sample? {
        val rounded = measured.filterValues { it.isSendable }.mapValues { (key, value) -> round(value, key) }
        val full = when (mode) {
            SendMode.EVERY_TICK -> true
            SendMode.ON_CHANGE -> fullSampleDue || lastFullSample.let { it == null || ts - it >= FULL_SAMPLE_INTERVAL }
        }
        val values = if (full) rounded else rounded.filter { (key, value) -> lastSent[key] != value }
        if (values.isEmpty()) return null
        if (full) {
            lastFullSample = ts
            fullSampleDue = false
        }
        lastSent += values
        return Sample(ts, values)
    }

    companion object {
        /** The interval of the full sample, in milliseconds. It is fixed, not a setting. */
        const val FULL_SAMPLE_INTERVAL = 60_000L

        /** Rounds a number to the resolution of its key. Other values stay as they are. */
        fun round(value: TelemetryValue, key: String): TelemetryValue {
            val resolution = Catalog.resolutionOf(key)
            return if (value is TelemetryValue.Number && resolution != null) {
                TelemetryValue.Number(resolution.round(value.value))
            } else {
                value
            }
        }
    }
}

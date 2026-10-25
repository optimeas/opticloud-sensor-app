package com.optimeas.opticloudsensor.core

/** Whether a value is sampled at every tick, aggregated between ticks, or sent when it arrives. */
enum class Kind { SAMPLED, AGGREGATED, EVENT }

/**
 * The smallest unit the user can select. [valueKeys] are the keys of its values in a sample; an aggregated
 * item also sends each of them with `Min` and `Max`. [resolution] is null for values that are not numbers.
 */
data class Item(val key: String, val valueKeys: List<String>, val resolution: Resolution?, val kind: Kind)

data class Group(val key: String, val items: List<Item>)

/** The catalog of groups, items, keys, and resolutions (see `docs/spec/sensors.md`, Catalog). */
object Catalog {
    private fun item(key: String, resolution: Int?, kind: Kind, vararg valueKeys: String) =
        Item(key, if (valueKeys.isEmpty()) listOf(key) else valueKeys.toList(), resolution?.let(::Resolution), kind)

    private val S = Kind.SAMPLED
    private val A = Kind.AGGREGATED
    private val E = Kind.EVENT

    val groups: List<Group> = listOf(
        Group(
            "motion",
            listOf(
                item("accel", -2, A, "accelX", "accelY", "accelZ"),
                item("accelMagnitude", -2, A),
                item("gyro", -3, A, "gyroX", "gyroY", "gyroZ"),
                item("mag", -1, S, "magX", "magY", "magZ"),
                item("orientation", -1, S, "roll", "pitch", "yaw"),
            ),
        ),
        Group(
            "environment",
            listOf(
                item("pressure", -1, S),
                item("light", 0, S),
            ),
        ),
        Group(
            "location",
            listOf(
                item("position", -5, S, "latitude", "longitude"),
                item("altitude", -1, S),
                item("speed", -1, S),
                item("course", 0, S),
                item("locationAccuracy", 0, S),
            ),
        ),
        Group(
            "activity",
            listOf(
                item("steps", 0, S),
                item("activityType", null, E),
            ),
        ),
        Group(
            "device",
            listOf(
                item("batteryLevel", -2, S),
                item("charging", null, S),
                item("network", null, S),
                item("thermalState", null, S),
                item("powerSaving", null, S),
                item("cellularSignal", 0, S),
                item("dataVolume", 3, S, "dataMobileToday", "dataWifiToday", "dataMobileMonth", "dataWifiMonth"),
            ),
        ),
        Group(
            "sound",
            listOf(
                item("soundLevel", 0, S),
            ),
        ),
        // Planned for stage 4; known to the selection, but not offered before.
        Group(
            "health",
            listOf(
                item("heartRate", 0, E),
                item("bodyTemperature", -1, E),
                item("oxygenSaturation", 0, E),
                item("respiratoryRate", 0, E),
            ),
        ),
    )

    /** All items in catalog order. */
    val items: List<Item> = groups.flatMap { it.items }

    private val groupsByKey = groups.associateBy { it.key }
    private val itemsByKey = items.associateBy { it.key }

    private val resolutionsByValueKey: Map<String, Resolution> = buildMap {
        for (item in items) {
            val resolution = item.resolution ?: continue
            for (key in item.valueKeys) {
                put(key, resolution)
                if (item.kind == Kind.AGGREGATED) {
                    put(key + "Min", resolution)
                    put(key + "Max", resolution)
                }
            }
        }
    }

    fun group(key: String): Group? = groupsByKey[key]

    fun item(key: String): Item? = itemsByKey[key]

    /** The resolution of a value key such as `accelX` or `accelXMin`, or null if the value is not a number. */
    fun resolutionOf(valueKey: String): Resolution? = resolutionsByValueKey[valueKey]
}

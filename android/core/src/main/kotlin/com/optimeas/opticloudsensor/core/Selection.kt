package com.optimeas.opticloudsensor.core

/**
 * The selection of sensors for transmission: a set of item keys (see `docs/spec/sensors.md`, Selection).
 */
class Selection private constructor(val selected: Set<String>) {
    /** The selected items the phone offers, in catalog order. */
    fun items(offered: Set<String>): List<String> =
        Catalog.items.map { it.key }.filter { it in selected && it in offered }

    /**
     * The entries the app reports: a group key for each group that has at least one offered item and whose
     * offered items are all selected, and item keys for the other selected items the phone offers.
     */
    fun report(offered: Set<String>): List<String> = Catalog.groups.flatMap { group ->
        val groupOffered = group.items.map { it.key }.filter { it in offered }
        val groupSelected = groupOffered.filter { it in selected }
        when {
            groupOffered.isEmpty() || groupSelected.isEmpty() -> emptyList()
            groupSelected.size == groupOffered.size -> listOf(group.key)
            else -> groupSelected
        }
    }

    override fun equals(other: Any?) = other is Selection && other.selected == selected

    override fun hashCode() = selected.hashCode()

    override fun toString() = "Selection($selected)"

    companion object {
        /**
         * Reads a selection such as `location,accelMagnitude`. Spaces around an entry and empty entries are
         * ignored. Returns null if an entry is neither a group key nor an item key: the selection is then
         * invalid as a whole.
         */
        fun parse(text: String): Selection? {
            val selected = mutableSetOf<String>()
            for (entry in text.split(',').map { it.trim() }.filter { it.isNotEmpty() }) {
                val group = Catalog.group(entry)
                when {
                    group != null -> group.items.mapTo(selected) { it.key }
                    Catalog.item(entry) != null -> selected += entry
                    else -> return null
                }
            }
            return Selection(selected)
        }
    }
}

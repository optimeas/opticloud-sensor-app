package com.optimeas.opticloudsensor.storage

import android.content.ContentValues
import android.content.Context
import android.database.DatabaseUtils
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import androidx.core.content.edit
import com.optimeas.opticloudsensor.core.connection.Discarded
import com.optimeas.opticloudsensor.core.connection.QueueStore
import com.optimeas.opticloudsensor.core.connection.QueuedSample

/** The offline queue in a database on the phone; it survives a restart of the app and of the phone. */
class SqliteQueueStore(context: Context) : QueueStore {
    private val database = Helper(context).writableDatabase
    private val preferences = context.getSharedPreferences("queue", Context.MODE_PRIVATE)

    // Kept in memory, so that the status does not scan the table at every sample.
    override var count: Long = DatabaseUtils.queryNumEntries(database, TABLE)
        private set
    override var bytes: Long = DatabaseUtils.longForQuery(database, "SELECT COALESCE(SUM(size), 0) FROM $TABLE", null)
        private set

    override fun append(ts: Long, json: String, size: Int) {
        database.insert(TABLE, null, ContentValues().apply {
            put("ts", ts)
            put("json", json)
            put("size", size)
        })
        count++
        bytes += size
    }

    override fun front(limit: Int): List<QueuedSample> =
        database.rawQuery("SELECT id, ts, json, size FROM $TABLE ORDER BY id LIMIT $limit", null).use { cursor ->
            buildList {
                while (cursor.moveToNext()) add(QueuedSample(cursor.getLong(0), cursor.getLong(1), cursor.getString(2), cursor.getInt(3)))
            }
        }

    override fun remove(ids: Collection<Long>) {
        if (ids.isEmpty()) return
        database.beginTransaction()
        try {
            for (chunk in ids.chunked(500)) {
                val where = "id IN (${chunk.joinToString(",")})"
                bytes -= DatabaseUtils.longForQuery(database, "SELECT COALESCE(SUM(size), 0) FROM $TABLE WHERE $where", null)
                count -= database.delete(TABLE, where, null)
            }
            database.setTransactionSuccessful()
        } finally {
            database.endTransaction()
        }
    }

    override val oldestTs: Long?
        get() = database.rawQuery("SELECT MIN(ts) FROM $TABLE", null).use { cursor ->
            if (cursor.moveToFirst() && !cursor.isNull(0)) cursor.getLong(0) else null
        }

    override var discarded: Discarded
        get() = Discarded(
            preferences.getLong(DISCARDED, 0),
            preferences.getLong(FIRST, -1).takeIf { it >= 0 },
            preferences.getLong(LAST, -1).takeIf { it >= 0 },
        )
        set(value) = preferences.edit {
            putLong(DISCARDED, value.count)
            putLong(FIRST, value.firstTs ?: -1)
            putLong(LAST, value.lastTs ?: -1)
        }

    override fun clear() {
        database.delete(TABLE, null, null)
        count = 0
        bytes = 0
    }

    private class Helper(context: Context) : SQLiteOpenHelper(context, "queue.db", null, 1) {
        override fun onCreate(db: SQLiteDatabase) {
            db.execSQL("CREATE TABLE $TABLE (id INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER NOT NULL, json TEXT NOT NULL, size INTEGER NOT NULL)")
            db.execSQL("CREATE INDEX telemetry_ts ON $TABLE (ts)")
        }

        override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit
    }

    private companion object {
        const val TABLE = "telemetry"
        const val DISCARDED = "discarded"
        const val FIRST = "discardedFirstTs"
        const val LAST = "discardedLastTs"
    }
}

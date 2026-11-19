package app.minifocus.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [ModeEntity::class, TagEntity::class, SessionEntity::class],
    version = 1,
    exportSchema = false,
)
abstract class MiniFocusDatabase : RoomDatabase() {
    abstract fun modeDao(): ModeDao
    abstract fun tagDao(): TagDao
    abstract fun sessionDao(): SessionDao

    companion object {
        @Volatile
        private var instance: MiniFocusDatabase? = null

        fun get(context: Context): MiniFocusDatabase =
            instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    MiniFocusDatabase::class.java,
                    "minifocus.db",
                ).build().also { instance = it }
            }
    }
}

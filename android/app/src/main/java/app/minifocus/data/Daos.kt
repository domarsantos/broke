package app.minifocus.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

@Dao
interface ModeDao {
    @Query("SELECT * FROM modes ORDER BY createdAt ASC")
    suspend fun fetchAll(): List<ModeEntity>

    @Query("SELECT * FROM modes WHERE id = :id LIMIT 1")
    suspend fun fetch(id: String): ModeEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: ModeEntity)

    @Update
    suspend fun update(entity: ModeEntity)

    @Query("DELETE FROM modes WHERE id = :id")
    suspend fun delete(id: String)
}

@Dao
interface TagDao {
    @Query("SELECT * FROM tags ORDER BY createdAt ASC")
    suspend fun fetchAll(): List<TagEntity>

    @Query("SELECT * FROM tags WHERE id = :id LIMIT 1")
    suspend fun fetch(id: String): TagEntity?

    @Query("SELECT * FROM tags WHERE hardwareIdentifier = :hardwareIdentifier LIMIT 1")
    suspend fun fetchByHardware(hardwareIdentifier: String): TagEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: TagEntity)

    @Update
    suspend fun update(entity: TagEntity)

    @Query("DELETE FROM tags WHERE id = :id")
    suspend fun delete(id: String)

    @Query("UPDATE tags SET linkedModeId = NULL WHERE linkedModeId = :modeId")
    suspend fun unlinkMode(modeId: String)
}

@Dao
interface SessionDao {
    @Query("SELECT * FROM sessions ORDER BY startedAt DESC")
    suspend fun fetchAll(): List<SessionEntity>

    @Query("SELECT * FROM sessions WHERE id = :id LIMIT 1")
    suspend fun fetch(id: String): SessionEntity?

    @Query("SELECT * FROM sessions WHERE status = 'ACTIVE' AND endedAt IS NULL ORDER BY startedAt DESC")
    suspend fun fetchActive(): List<SessionEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: SessionEntity)

    @Update
    suspend fun update(entity: SessionEntity)

    @Query("DELETE FROM sessions WHERE id = :id")
    suspend fun delete(id: String)
}

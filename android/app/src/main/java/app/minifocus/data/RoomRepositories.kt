package app.minifocus.data

import app.minifocus.domain.FocusSession
import app.minifocus.domain.FocusTag
import app.minifocus.domain.Mode
import java.util.UUID

/** Room-backed implementations of the repository interfaces. */

class RoomModeRepository(private val dao: ModeDao) : ModeRepository {
    override suspend fun fetchAll(): List<Mode> = dao.fetchAll().map { it.toDomain() }
    override suspend fun fetch(id: UUID): Mode? = dao.fetch(id.toString())?.toDomain()
    override suspend fun create(mode: Mode) = dao.insert(ModeEntity.from(mode))
    override suspend fun update(mode: Mode) = dao.update(ModeEntity.from(mode))
    override suspend fun delete(id: UUID) = dao.delete(id.toString())
}

class RoomTagRepository(private val dao: TagDao) : TagRepository {
    override suspend fun fetchAll(): List<FocusTag> = dao.fetchAll().map { it.toDomain() }
    override suspend fun fetch(id: UUID): FocusTag? = dao.fetch(id.toString())?.toDomain()
    override suspend fun fetch(hardwareIdentifier: String): FocusTag? =
        dao.fetchByHardware(hardwareIdentifier)?.toDomain()

    override suspend fun register(tag: FocusTag) = dao.insert(TagEntity.from(tag))
    override suspend fun update(tag: FocusTag) = dao.update(TagEntity.from(tag))
    override suspend fun delete(id: UUID) = dao.delete(id.toString())
    override suspend fun unlinkMode(modeId: UUID) = dao.unlinkMode(modeId.toString())
}

class RoomSessionRepository(private val dao: SessionDao) : SessionRepository {
    override suspend fun fetchAll(): List<FocusSession> = dao.fetchAll().map { it.toDomain() }
    override suspend fun fetch(id: UUID): FocusSession? = dao.fetch(id.toString())?.toDomain()
    override suspend fun fetchActive(): List<FocusSession> = dao.fetchActive().map { it.toDomain() }
    override suspend fun create(session: FocusSession) = dao.insert(SessionEntity.from(session))
    override suspend fun update(session: FocusSession) = dao.update(SessionEntity.from(session))
    override suspend fun delete(id: UUID) = dao.delete(id.toString())
}

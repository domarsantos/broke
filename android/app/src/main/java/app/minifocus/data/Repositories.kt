package app.minifocus.data

import app.minifocus.domain.FocusSession
import app.minifocus.domain.FocusTag
import app.minifocus.domain.Mode
import java.util.UUID

/**
 * Persistence abstractions. Domain and UI depend only on these interfaces,
 * never on the concrete (Room) implementation. Faithful port of
 * `MiniFocus/Repositories/RepositoryProtocols.swift`; methods are suspend
 * because Room I/O must stay off the main thread.
 */
interface ModeRepository {
    suspend fun fetchAll(): List<Mode>
    suspend fun fetch(id: UUID): Mode?
    suspend fun create(mode: Mode)
    suspend fun update(mode: Mode)
    suspend fun delete(id: UUID)
}

interface TagRepository {
    suspend fun fetchAll(): List<FocusTag>
    suspend fun fetch(id: UUID): FocusTag?

    /** Look up a registered tag by its physical identifier (UID). */
    suspend fun fetch(hardwareIdentifier: String): FocusTag?
    suspend fun register(tag: FocusTag)
    suspend fun update(tag: FocusTag)
    suspend fun delete(id: UUID)

    /** Remove the link to a given Mode from any tags that reference it. */
    suspend fun unlinkMode(modeId: UUID)
}

interface SessionRepository {
    suspend fun fetchAll(): List<FocusSession>
    suspend fun fetch(id: UUID): FocusSession?

    /** All sessions still marked active (normally zero or one). */
    suspend fun fetchActive(): List<FocusSession>
    suspend fun create(session: FocusSession)
    suspend fun update(session: FocusSession)
    suspend fun delete(id: UUID)
}

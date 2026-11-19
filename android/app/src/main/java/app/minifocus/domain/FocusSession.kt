package app.minifocus.domain

import java.time.Duration
import java.time.Instant
import java.util.UUID

/**
 * What caused a focus session to start. String-backed so future triggers
 * (timer, schedule, remote) can be added without breaking stored data.
 */
enum class FocusTrigger { NFC, MANUAL }

/** Lifecycle status of a focus session. */
enum class FocusSessionStatus { ACTIVE, COMPLETED }

/** A record of a Mode being active for a period of time. */
data class FocusSession(
    val id: UUID = UUID.randomUUID(),
    val modeId: UUID,
    val startedAt: Instant = Instant.now(),
    val endedAt: Instant? = null,
    val trigger: FocusTrigger,
    val status: FocusSessionStatus = FocusSessionStatus.ACTIVE,
    /** The tag that started the session, when applicable. */
    val tagId: UUID? = null,
) {
    val isActive: Boolean get() = status == FocusSessionStatus.ACTIVE && endedAt == null

    val duration: Duration get() = Duration.between(startedAt, endedAt ?: Instant.now())
}

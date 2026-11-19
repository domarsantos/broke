package app.minifocus.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverter
import app.minifocus.domain.FocusSession
import app.minifocus.domain.FocusSessionStatus
import app.minifocus.domain.FocusTag
import app.minifocus.domain.FocusTrigger
import app.minifocus.domain.Mode
import java.time.Instant
import java.util.UUID

/**
 * Room persistence layer (local-first). Entities reference each other by UUID
 * (not Room relationships) to keep deletes simple and to mirror what a future
 * cloud backend would use — same design decision as the iOS SwiftData schema.
 */

@Entity(tableName = "modes")
data class ModeEntity(
    @PrimaryKey val id: String,
    val name: String,
    val icon: String,
    /** Comma-separated set of package names to limit. */
    val packages: String,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toDomain(): Mode = Mode(
        id = UUID.fromString(id),
        name = name,
        icon = icon,
        packages = packages.split(",").map { it.trim() }.filter { it.isNotEmpty() }.toSet(),
        createdAt = Instant.ofEpochMilli(createdAt),
        updatedAt = Instant.ofEpochMilli(updatedAt),
    )

    companion object {
        fun from(mode: Mode): ModeEntity = ModeEntity(
            id = mode.id.toString(),
            name = mode.name,
            icon = mode.icon,
            packages = mode.packages.joinToString(","),
            createdAt = mode.createdAt.toEpochMilli(),
            updatedAt = mode.updatedAt.toEpochMilli(),
        )
    }
}

@Entity(tableName = "tags")
data class TagEntity(
    @PrimaryKey val id: String,
    val hardwareIdentifier: String?,
    val name: String,
    val createdAt: Long,
    val linkedModeId: String?,
) {
    fun toDomain(): FocusTag = FocusTag(
        id = UUID.fromString(id),
        hardwareIdentifier = hardwareIdentifier,
        name = name,
        createdAt = Instant.ofEpochMilli(createdAt),
        linkedModeId = linkedModeId?.let { UUID.fromString(it) },
    )

    companion object {
        fun from(tag: FocusTag): TagEntity = TagEntity(
            id = tag.id.toString(),
            hardwareIdentifier = tag.hardwareIdentifier,
            name = tag.name,
            createdAt = tag.createdAt.toEpochMilli(),
            linkedModeId = tag.linkedModeId?.toString(),
        )
    }
}

@Entity(tableName = "sessions")
data class SessionEntity(
    @PrimaryKey val id: String,
    val modeId: String,
    val startedAt: Long,
    val endedAt: Long?,
    val trigger: String,
    val status: String,
    val tagId: String?,
) {
    fun toDomain(): FocusSession = FocusSession(
        id = UUID.fromString(id),
        modeId = UUID.fromString(modeId),
        startedAt = Instant.ofEpochMilli(startedAt),
        endedAt = endedAt?.let { Instant.ofEpochMilli(it) },
        trigger = FocusTrigger.valueOf(trigger),
        status = FocusSessionStatus.valueOf(status),
        tagId = tagId?.let { UUID.fromString(it) },
    )

    companion object {
        fun from(session: FocusSession): SessionEntity = SessionEntity(
            id = session.id.toString(),
            modeId = session.modeId.toString(),
            startedAt = session.startedAt.toEpochMilli(),
            endedAt = session.endedAt?.toEpochMilli(),
            trigger = session.trigger.name,
            status = session.status.name,
            tagId = session.tagId?.toString(),
        )
    }
}

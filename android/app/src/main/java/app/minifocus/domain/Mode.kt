package app.minifocus.domain

import java.time.Instant
import java.util.UUID

/**
 * A Mode represents a focus context (Work, Study, Sleep, ...).
 *
 * On iOS the restricted set is an opaque Apple `FamilyActivitySelection`. On
 * Android there is no equivalent system token, so a Mode simply stores the set
 * of application package names to limit while the Mode is active. The limiting
 * itself is performed by the accessibility service.
 */
data class Mode(
    val id: UUID = UUID.randomUUID(),
    val name: String,
    val icon: String = DEFAULT_ICON,
    val packages: Set<String> = emptySet(),
    val createdAt: Instant = Instant.now(),
    val updatedAt: Instant = Instant.now(),
) {
    /** True when this Mode would not restrict anything. */
    val isEmpty: Boolean get() = packages.isEmpty()

    companion object {
        /** Mirrors the iOS default icon `bell.slash`. */
        const val DEFAULT_ICON = "notifications_off"
    }
}

package app.minifocus.domain

import java.time.Instant
import java.util.UUID

/**
 * A physical NFC tag registered by the user.
 *
 * [hardwareIdentifier] is the tag UID (upper-case hex string) obtained from the
 * NFC stack. It is used for identification and pairing only, not as a
 * cryptographic secret. A tag may optionally be linked to a [Mode].
 */
data class FocusTag(
    val id: UUID = UUID.randomUUID(),
    val hardwareIdentifier: String? = null,
    val name: String,
    val createdAt: Instant = Instant.now(),
    val linkedModeId: UUID? = null,
)

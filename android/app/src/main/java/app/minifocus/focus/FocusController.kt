package app.minifocus.focus

import android.util.Log
import app.minifocus.block.FocusBlocker
import app.minifocus.data.ModeRepository
import app.minifocus.data.SessionRepository
import app.minifocus.data.TagRepository
import app.minifocus.domain.FocusAction
import app.minifocus.domain.FocusRules
import app.minifocus.domain.FocusSession
import app.minifocus.domain.FocusSessionStatus
import app.minifocus.domain.FocusTrigger
import app.minifocus.domain.Mode
import app.minifocus.nfc.ScannedTag
import java.time.Instant
import java.util.UUID

/** The user-visible result of handling a scan. Mirrors iOS `FocusOutcome`. */
sealed interface FocusOutcome {
    data class Activated(val mode: Mode) : FocusOutcome
    data object Deactivated : FocusOutcome
    data class Switched(val mode: Mode) : FocusOutcome
    data class Unregistered(val scanned: ScannedTag) : FocusOutcome
    data object NoModeToActivate : FocusOutcome
}

class FocusControllerException(message: String) : Exception(message)

/**
 * The single source of truth for the active focus session. Faithful port of
 * `MiniFocus/Services/FocusController.swift`: it owns domain-rule execution,
 * session persistence and app limiting. Views call into this; they never touch
 * repositories, rules, NFC or the blocker directly for activation logic.
 *
 * All methods are `suspend` because the repositories are backed by Room.
 */
class FocusController(
    private val modeRepository: ModeRepository,
    private val tagRepository: TagRepository,
    private val sessionRepository: SessionRepository,
    private val blocker: FocusBlocker,
) {
    var activeSession: FocusSession? = null
        private set
    var activeMode: Mode? = null
        private set

    val isActive: Boolean get() = activeSession?.isActive == true

    // MARK: - Scan handling

    /** Resolve a scanned tag and apply the matching focus rule. */
    suspend fun handleScan(scanned: ScannedTag, fallbackModeId: UUID?): FocusOutcome {
        val tag = tagRepository.fetch(hardwareIdentifier = scanned.hardwareIdentifier)
        return when (val action = FocusRules.action(tag, activeSession, fallbackModeId)) {
            is FocusAction.Unregistered -> FocusOutcome.Unregistered(scanned)
            is FocusAction.NoModeToActivate -> FocusOutcome.NoModeToActivate
            is FocusAction.Activate -> {
                val mode = startSession(action.modeId, FocusTrigger.NFC, action.tagId)
                FocusOutcome.Activated(mode)
            }
            is FocusAction.Deactivate -> {
                stop()
                FocusOutcome.Deactivated
            }
            is FocusAction.SwitchTo -> {
                val mode = switchSession(action.modeId, action.tagId)
                FocusOutcome.Switched(mode)
            }
        }
    }

    // MARK: - Manual control

    /** Start a session manually (no tag). Only allowed when nothing is running. */
    suspend fun startManual(modeId: UUID): Mode? {
        if (isActive) return null
        return startSession(modeId, FocusTrigger.MANUAL, tagId = null)
    }

    // MARK: - Lifecycle recovery

    /**
     * Restore state after a cold launch. Reapplies limiting for a running
     * session, or clears it if nothing should be active.
     */
    suspend fun recover() {
        try {
            val active = sessionRepository.fetchActive().sortedByDescending { it.startedAt }

            val current = active.firstOrNull()
            if (current == null) {
                blocker.clearRestrictions()
                activeSession = null
                activeMode = null
                return
            }

            // End any stray extra active sessions (should not normally happen).
            active.drop(1).forEach { endPersisted(it) }

            val mode = modeRepository.fetch(current.modeId)
            if (mode == null) {
                // Mode was deleted while a session was running: end and clear.
                endPersisted(current)
                blocker.clearRestrictions()
                activeSession = null
                activeMode = null
                return
            }

            activeSession = current
            activeMode = mode
            blocker.apply(mode)
        } catch (e: Exception) {
            Log.e(TAG, "recover failed", e)
        }
    }

    // MARK: - Private

    private suspend fun startSession(modeId: UUID, trigger: FocusTrigger, tagId: UUID?): Mode {
        val mode = modeRepository.fetch(modeId)
            ?: throw FocusControllerException("Mode not found")
        val session = FocusSession(modeId = modeId, trigger = trigger, tagId = tagId)
        // Persist BEFORE applying limiting so the state survives a crash.
        sessionRepository.create(session)
        blocker.apply(mode)
        activeSession = session
        activeMode = mode
        return mode
    }

    private suspend fun stop() {
        val current = activeSession ?: return
        endPersisted(current)
        blocker.clearRestrictions()
        activeSession = null
        activeMode = null
    }

    private suspend fun switchSession(modeId: UUID, tagId: UUID?): Mode {
        activeSession?.let { endPersisted(it) }
        return startSession(modeId, FocusTrigger.NFC, tagId)
    }

    private suspend fun endPersisted(session: FocusSession) {
        val ended = session.copy(endedAt = Instant.now(), status = FocusSessionStatus.COMPLETED)
        sessionRepository.update(ended)
    }

    private companion object {
        const val TAG = "FocusController"
    }
}

package app.minifocus.domain

import java.util.UUID

/**
 * The decision produced by the rules engine for a given scan. Mirrors the iOS
 * `FocusAction` enum.
 */
sealed interface FocusAction {
    /** Tag is not registered in the app. */
    data object Unregistered : FocusAction

    /**
     * No session running and nothing to activate (registered tag, no linked
     * Mode and no fallback Mode available).
     */
    data object NoModeToActivate : FocusAction

    /** Start a session for this Mode. */
    data class Activate(val modeId: UUID, val tagId: UUID) : FocusAction

    /** Stop the running session. */
    data object Deactivate : FocusAction

    /** Stop the running session and start one for a different Mode. */
    data class SwitchTo(val modeId: UUID, val tagId: UUID) : FocusAction
}

/**
 * Pure, hardware-free business rules for what a tag scan should do. Faithful
 * port of `MiniFocus/Domain/FocusRules.swift`, kept as a plain function so the
 * core behaviour is fully unit-testable.
 */
object FocusRules {
    /**
     * Decide what to do when [tag] is scanned.
     *
     * @param tag the registered tag matching the scanned UID, or null if unknown.
     * @param activeSession the session currently running, if any.
     * @param fallbackModeId the Mode to use when a registered tag has no linked
     *   Mode (e.g. the Mode currently selected on the home screen).
     */
    fun action(
        tag: FocusTag?,
        activeSession: FocusSession?,
        fallbackModeId: UUID?,
    ): FocusAction {
        if (tag == null) return FocusAction.Unregistered

        val targetModeId = tag.linkedModeId ?: fallbackModeId

        if (activeSession == null || !activeSession.isActive) {
            // Nothing running: try to activate.
            val modeId = targetModeId ?: return FocusAction.NoModeToActivate
            return FocusAction.Activate(modeId = modeId, tagId = tag.id)
        }

        // A session is running.
        // A tag with no specific Mode link always toggles off.
        val linkedModeId = tag.linkedModeId ?: return FocusAction.Deactivate

        if (linkedModeId == activeSession.modeId) {
            return FocusAction.Deactivate
        }

        return FocusAction.SwitchTo(modeId = linkedModeId, tagId = tag.id)
    }
}

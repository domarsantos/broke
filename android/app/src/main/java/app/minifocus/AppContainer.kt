package app.minifocus

import android.content.Context
import app.minifocus.block.AccessibilityFocusBlocker
import app.minifocus.block.FocusBlocker
import app.minifocus.data.MiniFocusDatabase
import app.minifocus.data.ModeRepository
import app.minifocus.data.RoomModeRepository
import app.minifocus.data.RoomSessionRepository
import app.minifocus.data.RoomTagRepository
import app.minifocus.data.SessionRepository
import app.minifocus.data.TagRepository
import app.minifocus.focus.FocusController

/**
 * Composition root. Wires the Room database, repositories, blocker and focus
 * controller together. The Android counterpart of iOS' `AppEnvironment`
 * (minus the NFC service, which is activity-scoped). Held by [MiniFocusApp].
 */
class AppContainer(context: Context) {
    private val database = MiniFocusDatabase.get(context)

    val modeRepository: ModeRepository = RoomModeRepository(database.modeDao())
    val tagRepository: TagRepository = RoomTagRepository(database.tagDao())
    val sessionRepository: SessionRepository = RoomSessionRepository(database.sessionDao())
    val blocker: FocusBlocker = AccessibilityFocusBlocker(context.applicationContext)

    val focusController = FocusController(
        modeRepository = modeRepository,
        tagRepository = tagRepository,
        sessionRepository = sessionRepository,
        blocker = blocker,
    )
}

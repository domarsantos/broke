package app.minifocus.domain

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.UUID

/**
 * Unit tests for the focus rules engine. These mirror the iOS
 * `MiniFocusTests/FocusRulesTests.swift` case for case, so both platforms share
 * the exact same behaviour.
 */
class FocusRulesTest {

    private val modeA: UUID = UUID.randomUUID()
    private val modeB: UUID = UUID.randomUUID()

    private fun tag(linkedTo: UUID?): FocusTag =
        FocusTag(hardwareIdentifier = "UID", name = "T", linkedModeId = linkedTo)

    private fun activeSession(mode: UUID): FocusSession =
        FocusSession(modeId = mode, trigger = FocusTrigger.NFC, status = FocusSessionStatus.ACTIVE)

    @Test
    fun unregisteredTag() {
        val action = FocusRules.action(tag = null, activeSession = null, fallbackModeId = modeA)
        assertEquals(FocusAction.Unregistered, action)
    }

    @Test
    fun noSessionActivatesLinkedMode() {
        val t = tag(linkedTo = modeA)
        val action = FocusRules.action(tag = t, activeSession = null, fallbackModeId = null)
        assertEquals(FocusAction.Activate(modeId = modeA, tagId = t.id), action)
    }

    @Test
    fun noSessionUsesFallbackWhenTagHasNoMode() {
        val t = tag(linkedTo = null)
        val action = FocusRules.action(tag = t, activeSession = null, fallbackModeId = modeB)
        assertEquals(FocusAction.Activate(modeId = modeB, tagId = t.id), action)
    }

    @Test
    fun noSessionNoModeToActivate() {
        val t = tag(linkedTo = null)
        val action = FocusRules.action(tag = t, activeSession = null, fallbackModeId = null)
        assertEquals(FocusAction.NoModeToActivate, action)
    }

    @Test
    fun sameModeDeactivates() {
        val t = tag(linkedTo = modeA)
        val action = FocusRules.action(tag = t, activeSession = activeSession(modeA), fallbackModeId = null)
        assertEquals(FocusAction.Deactivate, action)
    }

    @Test
    fun differentModeSwitches() {
        val t = tag(linkedTo = modeB)
        val action = FocusRules.action(tag = t, activeSession = activeSession(modeA), fallbackModeId = null)
        assertEquals(FocusAction.SwitchTo(modeId = modeB, tagId = t.id), action)
    }

    @Test
    fun unlinkedTagDeactivatesRunningSession() {
        val t = tag(linkedTo = null)
        val action = FocusRules.action(tag = t, activeSession = activeSession(modeA), fallbackModeId = modeB)
        assertEquals(FocusAction.Deactivate, action)
    }
}

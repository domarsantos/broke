package app.minifocus.block

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.pm.PackageManager
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent

/**
 * Enforces app limiting while a focus session is active.
 *
 * This is the Android replacement for iOS ManagedSettings shields. There is no
 * system API to prevent an app from launching, so the service watches for the
 * foreground window changing and, if the opened package is in the active Mode's
 * limited set, immediately brings up the full-screen [BlockActivity] and sends
 * the user back home.
 *
 * The limited list is read from [BlockState] (SharedPreferences) so blocking
 * keeps working even if the UI process was killed.
 */
class FocusAccessibilityService : AccessibilityService() {

    /** Avoid relaunching the shield in a tight loop for the same event burst. */
    private var lastBlockAt = 0L

    private val homePackages: Set<String> by lazy { resolveHomePackages() }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        if (!BlockState.isActive(this)) return

        val packageName = event.packageName?.toString() ?: return
        if (!shouldBlock(packageName)) return

        val now = SystemClock.elapsedRealtime()
        if (now - lastBlockAt < DEBOUNCE_MS) return
        lastBlockAt = now

        // Send the user home, then raise the shield on top.
        performGlobalAction(GLOBAL_ACTION_HOME)
        startActivity(
            Intent(this, BlockActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
        )
    }

    override fun onInterrupt() {
        // Nothing to clean up: state lives in BlockState.
    }

    private fun shouldBlock(packageName: String): Boolean {
        if (packageName == this.packageName) return false
        if (packageName in homePackages) return false
        if (packageName.startsWith("com.android.systemui")) return false
        if (packageName.startsWith("com.android.inputmethod")) return false
        return packageName in BlockState.blockedPackages(this)
    }

    private fun resolveHomePackages(): Set<String> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        return packageManager
            .queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
            .map { it.activityInfo.packageName }
            .toSet()
    }

    private companion object {
        const val DEBOUNCE_MS = 400L
    }
}

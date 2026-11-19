package app.minifocus.block

import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import android.text.TextUtils
import app.minifocus.domain.Mode

/**
 * Owns all app-limiting interaction. Views and domain logic never touch the
 * accessibility layer directly. This is the Android counterpart of iOS'
 * `ScreenTimeService`:
 *
 * - `isAuthorized` reflects whether the user has enabled the accessibility
 *   service (the equivalent of Screen Time authorization). The app can only
 *   send the user to the system settings screen; it cannot grant it.
 * - `apply`/`clearRestrictions` publish the active package set to [BlockState],
 *   which the running [FocusAccessibilityService] consults.
 */
interface FocusBlocker {
    val isAuthorized: Boolean
    fun openAuthorizationSettings()
    fun apply(mode: Mode)
    fun clearRestrictions()
}

class AccessibilityFocusBlocker(private val context: Context) : FocusBlocker {

    override val isAuthorized: Boolean
        get() = isAccessibilityServiceEnabled(context)

    override fun openAuthorizationSettings() {
        val intent = android.content.Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    override fun apply(mode: Mode) {
        BlockState.setActive(context, active = true, packages = mode.packages)
    }

    override fun clearRestrictions() {
        BlockState.clear(context)
    }

    private fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val expected = ComponentName(context, FocusAccessibilityService::class.java)
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false

        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabled)
        while (splitter.hasNext()) {
            val component = ComponentName.unflattenFromString(splitter.next())
            if (component != null && component == expected) return true
        }
        return false
    }
}

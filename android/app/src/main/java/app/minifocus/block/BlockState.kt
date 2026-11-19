package app.minifocus.block

import android.content.Context

/**
 * The source of truth the accessibility service reads to decide what to block.
 *
 * It lives in SharedPreferences (not only Room) so the block survives the UI
 * process being killed: the accessibility service can run in its own process
 * and still read an up-to-date list without touching the database on its hot
 * path. Written by [FocusBlocker], read by [FocusAccessibilityService].
 */
object BlockState {
    private const val PREFS = "mini_focus_block_state"
    private const val KEY_ACTIVE = "active"
    private const val KEY_PACKAGES = "packages"

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun setActive(context: Context, active: Boolean, packages: Set<String>) {
        prefs(context).edit()
            .putBoolean(KEY_ACTIVE, active)
            .putStringSet(KEY_PACKAGES, packages)
            .apply()
    }

    fun clear(context: Context) {
        prefs(context).edit()
            .putBoolean(KEY_ACTIVE, false)
            .putStringSet(KEY_PACKAGES, emptySet())
            .apply()
    }

    fun isActive(context: Context): Boolean =
        prefs(context).getBoolean(KEY_ACTIVE, false)

    fun blockedPackages(context: Context): Set<String> =
        prefs(context).getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()
}

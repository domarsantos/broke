package app.minifocus.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material.icons.filled.PhoneAndroid
import androidx.compose.material.icons.filled.SelfImprovement
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Work
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Fixed catalog of Mode icons. Keys are stable strings stored on the Mode (the
 * Android counterpart of the iOS SF Symbol names). The default key
 * `notifications_off` mirrors iOS' `bell.slash`.
 */
object ModeIcons {
    private val byKey: Map<String, ImageVector> = linkedMapOf(
        "notifications_off" to Icons.Filled.NotificationsOff,
        "work" to Icons.Filled.Work,
        "school" to Icons.Filled.School,
        "bedtime" to Icons.Filled.Bedtime,
        "self_improvement" to Icons.Filled.SelfImprovement,
        "fitness_center" to Icons.Filled.FitnessCenter,
        "menu_book" to Icons.Filled.MenuBook,
        "home" to Icons.Filled.Home,
        "phone_android" to Icons.Filled.PhoneAndroid,
        "block" to Icons.Filled.Block,
    )

    val keys: List<String> get() = byKey.keys.toList()

    fun icon(key: String): ImageVector = byKey[key] ?: Icons.Filled.NotificationsOff
}

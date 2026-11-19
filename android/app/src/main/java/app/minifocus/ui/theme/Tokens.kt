package app.minifocus.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/**
 * Mini Focus design system tokens — the Android mirror of
 * `MiniFocus/Design/MiniTokens.swift`. Palette and scale come from the brand
 * kit (design/brand-kit/brand/design-tokens.json). Light appearance only, as
 * the brand kit does not define dark tokens for v1.0.
 */
object MiniColor {
    val primary = Color(0xFF183B35)
    val background = Color(0xFFF7F6F1)
    val surface = Color(0xFFFFFFFF)
    val sage = Color(0xFFDCE9E1)
    val text = Color(0xFF1D2824)
    val muted = Color(0xFF60756E)
    val line = Color(0xFFE3E9E4)
    val warm = Color(0xFFD6A678)
    val error = Color(0xFFA74336)
    val onPrimary = Color(0xFFFFFFFF)
}

object MiniSpacing {
    val xs = 8.dp
    val sm = 12.dp
    val md = 16.dp
    val lg = 24.dp
    val xl = 32.dp

    /** Horizontal screen margin. */
    val horizontal = 24.dp

    /** Gap between sibling components. */
    val component = 16.dp

    /** Gap between sections. */
    val section = 32.dp
}

object MiniRadius {
    val card = RoundedCornerShape(20.dp)
    val button = RoundedCornerShape(16.dp)
    val chip = RoundedCornerShape(999.dp)
}

object MiniControl {
    val buttonMinHeight = 52.dp
    val tapTargetMinSize = 44.dp
}

object MiniMotion {
    const val standardMillis = 200
}

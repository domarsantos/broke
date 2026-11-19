package app.minifocus.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/**
 * Mini Focus Material 3 theme. The app uses the system font (to support
 * accessibility/Dynamic Type equivalents) and a light-only brand color scheme.
 */
private val MiniColorScheme = lightColorScheme(
    primary = MiniColor.primary,
    onPrimary = MiniColor.onPrimary,
    secondary = MiniColor.sage,
    onSecondary = MiniColor.text,
    background = MiniColor.background,
    onBackground = MiniColor.text,
    surface = MiniColor.surface,
    onSurface = MiniColor.text,
    surfaceVariant = MiniColor.sage,
    onSurfaceVariant = MiniColor.muted,
    outline = MiniColor.line,
    error = MiniColor.error,
    onError = MiniColor.onPrimary,
)

private val MiniTypography = Typography(
    headlineLarge = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 32.sp, lineHeight = 38.sp),
    headlineMedium = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 24.sp, lineHeight = 30.sp),
    titleLarge = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 22.sp, lineHeight = 28.sp),
    bodyLarge = TextStyle(fontWeight = FontWeight.Normal, fontSize = 17.sp, lineHeight = 24.sp),
    bodyMedium = TextStyle(fontWeight = FontWeight.Normal, fontSize = 15.sp, lineHeight = 22.sp),
    labelLarge = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 17.sp, lineHeight = 22.sp),
    labelMedium = TextStyle(fontWeight = FontWeight.Medium, fontSize = 13.sp, lineHeight = 18.sp),
)

@Composable
fun MiniFocusTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = MiniColorScheme,
        typography = MiniTypography,
        content = content,
    )
}

package app.minifocus.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.minifocus.ui.theme.MiniColor
import app.minifocus.ui.theme.MiniControl
import app.minifocus.ui.theme.MiniRadius
import app.minifocus.ui.theme.MiniSpacing

/** Full-screen brand background wrapper. Mirrors iOS `MiniScreen`. */
@Composable
fun MiniScreen(content: @Composable () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MiniColor.background)
    ) {
        content()
    }
}

/** Rounded surface card with a hairline border. Mirrors iOS `MiniCard`. */
@Composable
fun MiniCard(
    modifier: Modifier = Modifier,
    fill: androidx.compose.ui.graphics.Color = MiniColor.surface,
    content: @Composable () -> Unit,
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = MiniRadius.card,
        color = fill,
        border = BorderStroke(1.dp, MiniColor.line),
    ) {
        Column(modifier = Modifier.padding(MiniSpacing.md)) {
            content()
        }
    }
}

@Composable
fun MiniPrimaryButton(
    text: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = MiniControl.buttonMinHeight),
        shape = MiniRadius.button,
        colors = ButtonDefaults.buttonColors(
            containerColor = MiniColor.primary,
            contentColor = MiniColor.onPrimary,
        ),
    ) {
        Text(text)
    }
}

@Composable
fun MiniSecondaryButton(
    text: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = MiniControl.buttonMinHeight),
        shape = MiniRadius.button,
        border = BorderStroke(1.dp, MiniColor.primary),
        colors = ButtonDefaults.outlinedButtonColors(contentColor = MiniColor.primary),
    ) {
        Text(text)
    }
}

@Composable
fun MiniQuietButton(
    text: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    TextButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.fillMaxWidth(),
        colors = ButtonDefaults.textButtonColors(contentColor = MiniColor.muted),
    ) {
        Text(text)
    }
}

/**
 * Icon + title status block. Never relies on color alone — an icon always
 * accompanies the state. Mirrors iOS `MiniStatusMark`.
 */
@Composable
fun MiniStatusMark(icon: ImageVector, title: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(MiniSpacing.md),
    ) {
        Surface(
            shape = CircleShape,
            color = MiniColor.sage,
            modifier = Modifier.size(84.dp),
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = MiniColor.primary,
                    modifier = Modifier.size(40.dp),
                )
            }
        }
        Text(
            text = title,
            color = MiniColor.text,
            textAlign = TextAlign.Center,
            style = androidx.compose.material3.MaterialTheme.typography.headlineLarge,
        )
    }
}

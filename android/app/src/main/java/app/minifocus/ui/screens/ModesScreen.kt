package app.minifocus.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.minifocus.domain.Mode
import app.minifocus.ui.MainViewModel
import app.minifocus.ui.MiniCard
import app.minifocus.ui.MiniCopy
import app.minifocus.ui.ModeIcons
import app.minifocus.ui.theme.MiniColor
import app.minifocus.ui.theme.MiniSpacing
import java.util.UUID

/** Lists Modes: tap to select, long-press to edit. Mirrors iOS `ModesView`. */
@Composable
fun ModesScreen(
    viewModel: MainViewModel,
    onNewMode: () -> Unit,
    onEditMode: (UUID) -> Unit,
) {
    val modes by viewModel.modes.collectAsState()
    val selectedId by viewModel.selectedModeId.collectAsState()

    if (modes.isEmpty()) {
        EmptyModes(onNewMode)
        return
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = MiniSpacing.horizontal),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(
            top = MiniSpacing.md,
            bottom = MiniSpacing.section,
        ),
        verticalArrangement = Arrangement.spacedBy(MiniSpacing.sm),
    ) {
        item {
            Text(
                MiniCopy.modesHint,
                style = MaterialTheme.typography.labelMedium,
                color = MiniColor.muted,
                modifier = Modifier.padding(bottom = MiniSpacing.xs),
            )
        }
        items(modes, key = { it.id }) { mode ->
            ModeCard(
                mode = mode,
                selected = mode.id == selectedId,
                onTap = { viewModel.selectMode(mode.id) },
                onLongPress = { onEditMode(mode.id) },
            )
        }
        item { AddModeCard(onNewMode) }
    }
}

@OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
private fun ModeCard(
    mode: Mode,
    selected: Boolean,
    onTap: () -> Unit,
    onLongPress: () -> Unit,
) {
    MiniCard(
        fill = if (selected) MiniColor.sage else MiniColor.surface,
        modifier = Modifier.combinedClickable(onClick = onTap, onLongClick = onLongPress),
    ) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = CircleShape, color = MiniColor.surface, modifier = Modifier.size(44.dp)) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(ModeIcons.icon(mode.icon), contentDescription = null, tint = MiniColor.primary, modifier = Modifier.size(22.dp))
                }
            }
            Column(modifier = Modifier.weight(1f).padding(start = MiniSpacing.md)) {
                Text(mode.name, style = MaterialTheme.typography.labelLarge, color = MiniColor.text)
                Text(
                    MiniCopy.modeAppsCount(mode.packages.size),
                    style = MaterialTheme.typography.labelMedium,
                    color = MiniColor.muted,
                )
            }
            if (selected) {
                Icon(Icons.Filled.CheckCircle, contentDescription = null, tint = MiniColor.primary, modifier = Modifier.size(24.dp))
            }
        }
    }
}

@Composable
private fun AddModeCard(onNewMode: () -> Unit) {
    MiniCard(modifier = Modifier.clickable(onClick = onNewMode)) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.Add, contentDescription = null, tint = MiniColor.primary, modifier = Modifier.size(24.dp))
            Text(
                MiniCopy.modesNew,
                style = MaterialTheme.typography.labelLarge,
                color = MiniColor.primary,
                modifier = Modifier.padding(start = MiniSpacing.sm),
            )
        }
    }
}

@Composable
private fun EmptyModes(onNewMode: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(MiniSpacing.horizontal),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(MiniSpacing.md, Alignment.CenterVertically),
    ) {
        Text(MiniCopy.modesEmptyTitle, style = MaterialTheme.typography.titleLarge, color = MiniColor.text, textAlign = TextAlign.Center)
        Text(MiniCopy.modesEmptyBody, style = MaterialTheme.typography.bodyLarge, color = MiniColor.muted, textAlign = TextAlign.Center)
        app.minifocus.ui.MiniPrimaryButton(text = MiniCopy.modesNew, onClick = onNewMode)
    }
}

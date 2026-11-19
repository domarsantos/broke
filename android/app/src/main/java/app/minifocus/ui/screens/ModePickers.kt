package app.minifocus.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import app.minifocus.ui.InstalledApp
import app.minifocus.ui.MiniCopy
import app.minifocus.ui.ModeIcons
import app.minifocus.ui.theme.MiniColor
import app.minifocus.ui.theme.MiniSpacing
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Full-screen dialog to choose which installed apps a Mode limits. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppPickerDialog(
    initiallySelected: Set<String>,
    loadApps: () -> List<InstalledApp>,
    onConfirm: (Set<String>) -> Unit,
    onDismiss: () -> Unit,
) {
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        var selected by remember { mutableStateOf(initiallySelected) }
        var query by remember { mutableStateOf("") }

        val apps by produceState<List<InstalledApp>?>(initialValue = null) {
            value = withContext(Dispatchers.IO) { loadApps() }
        }

        Scaffold(
            containerColor = MiniColor.background,
            topBar = {
                TopAppBar(
                    title = { Text(MiniCopy.modeSelectAppsTitle) },
                    navigationIcon = {
                        IconButton(onClick = onDismiss) { Icon(Icons.Filled.Close, contentDescription = MiniCopy.actionCancel) }
                    },
                    actions = {
                        TextButton(onClick = { onConfirm(selected) }) { Text(MiniCopy.actionDone) }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MiniColor.background,
                        titleContentColor = MiniColor.text,
                    ),
                )
            },
        ) { inner ->
            Column(modifier = Modifier.padding(inner).fillMaxSize()) {
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    placeholder = { Text(MiniCopy.modeAppsSearchPlaceholder) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = MiniSpacing.horizontal, vertical = MiniSpacing.xs),
                )

                val list = apps
                if (list == null) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                } else {
                    val filtered = remember(list, query) {
                        if (query.isBlank()) list
                        else list.filter { it.label.contains(query.trim(), ignoreCase = true) }
                    }
                    LazyColumn(modifier = Modifier.fillMaxSize()) {
                        items(filtered, key = { it.packageName }) { app ->
                            AppRow(
                                app = app,
                                checked = app.packageName in selected,
                                onToggle = {
                                    selected = if (app.packageName in selected) selected - app.packageName
                                    else selected + app.packageName
                                },
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun AppRow(app: InstalledApp, checked: Boolean, onToggle: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onToggle)
            .padding(horizontal = MiniSpacing.horizontal, vertical = MiniSpacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (app.icon != null) {
            Image(bitmap = app.icon, contentDescription = null, modifier = Modifier.size(36.dp))
        } else {
            Box(modifier = Modifier.size(36.dp))
        }
        Text(
            app.label,
            style = MaterialTheme.typography.bodyLarge,
            color = MiniColor.text,
            modifier = Modifier.weight(1f).padding(horizontal = MiniSpacing.md),
        )
        Checkbox(checked = checked, onCheckedChange = { onToggle() })
    }
}

/** Grid dialog to pick a Mode icon. */
@Composable
fun IconPickerDialog(
    current: String,
    onPick: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(shape = app.minifocus.ui.theme.MiniRadius.card, color = MiniColor.surface) {
            Column(modifier = Modifier.padding(MiniSpacing.md)) {
                Text(MiniCopy.modeIconPickerTitle, style = MaterialTheme.typography.titleLarge, color = MiniColor.text, modifier = Modifier.padding(bottom = MiniSpacing.sm))
                LazyVerticalGrid(
                    columns = GridCells.Fixed(4),
                    horizontalArrangement = Arrangement.spacedBy(MiniSpacing.sm),
                    verticalArrangement = Arrangement.spacedBy(MiniSpacing.sm),
                ) {
                    items(ModeIcons.keys, key = { it }) { key ->
                        val selected = key == current
                        Surface(
                            shape = CircleShape,
                            color = if (selected) MiniColor.primary else MiniColor.sage,
                            modifier = Modifier.size(56.dp).clickable { onPick(key) },
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    ModeIcons.icon(key),
                                    contentDescription = null,
                                    tint = if (selected) MiniColor.onPrimary else MiniColor.primary,
                                    modifier = Modifier.size(26.dp),
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

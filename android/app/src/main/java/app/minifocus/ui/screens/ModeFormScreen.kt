package app.minifocus.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.AlertDialog
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
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.minifocus.ui.InstalledApps
import app.minifocus.ui.MainViewModel
import app.minifocus.ui.MiniCard
import app.minifocus.ui.MiniCopy
import app.minifocus.ui.MiniPrimaryButton
import app.minifocus.ui.ModeIcons
import app.minifocus.ui.theme.MiniColor
import app.minifocus.ui.theme.MiniSpacing
import java.util.UUID

/** Create / edit a Mode, including the limited app set. Mirrors iOS `ModeFormView`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ModeFormScreen(
    viewModel: MainViewModel,
    modeId: UUID?,
    onClose: () -> Unit,
) {
    val modes by viewModel.modes.collectAsState()
    val existing = remember(modeId, modes) { modeId?.let { id -> modes.firstOrNull { it.id == id } } }

    var name by remember(existing) { mutableStateOf(existing?.name ?: "") }
    var icon by remember(existing) { mutableStateOf(existing?.icon ?: Mode_DEFAULT_ICON) }
    var packages by remember(existing) { mutableStateOf(existing?.packages ?: emptySet()) }

    var showIconPicker by remember { mutableStateOf(false) }
    var showAppPicker by remember { mutableStateOf(false) }
    var showDeleteConfirm by remember { mutableStateOf(false) }
    var showActiveDeleteAlert by remember { mutableStateOf(false) }

    val isEditing = existing != null
    val canSave = name.trim().isNotEmpty()

    Scaffold(
        containerColor = MiniColor.background,
        topBar = {
            TopAppBar(
                title = { Text(if (isEditing) MiniCopy.modeEditTitle else MiniCopy.modeAddTitle) },
                navigationIcon = {
                    IconButton(onClick = onClose) {
                        Icon(Icons.Filled.Close, contentDescription = MiniCopy.actionCancel)
                    }
                },
                actions = {
                    TextButton(
                        enabled = canSave,
                        onClick = {
                            if (isEditing) {
                                viewModel.updateMode(existing!!.id, name.trim(), icon, packages) { onClose() }
                            } else {
                                viewModel.addMode(name.trim(), icon, packages) { onClose() }
                            }
                        },
                    ) { Text(MiniCopy.actionSave) }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MiniColor.background,
                    titleContentColor = MiniColor.text,
                ),
            )
        },
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = MiniSpacing.horizontal, vertical = MiniSpacing.md),
            verticalArrangement = Arrangement.spacedBy(MiniSpacing.md),
        ) {
            Text(MiniCopy.modeDetailsSection, style = MaterialTheme.typography.labelMedium, color = MiniColor.muted)
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text(MiniCopy.modeNameLabel) },
                placeholder = { Text(MiniCopy.modeNamePlaceholder) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )

            MiniCard(modifier = Modifier.clickable { showIconPicker = true }) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(shape = CircleShape, color = MiniColor.sage, modifier = Modifier.size(44.dp)) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(ModeIcons.icon(icon), contentDescription = null, tint = MiniColor.primary, modifier = Modifier.size(22.dp))
                        }
                    }
                    Text(MiniCopy.modeChooseIcon, style = MaterialTheme.typography.bodyLarge, color = MiniColor.text, modifier = Modifier.padding(start = MiniSpacing.md))
                }
            }

            Text(MiniCopy.modeAppsSection, style = MaterialTheme.typography.labelMedium, color = MiniColor.muted, modifier = Modifier.padding(top = MiniSpacing.xs))
            MiniCard(modifier = Modifier.clickable { showAppPicker = true }) {
                Column {
                    Text(MiniCopy.modeConfigureApps, style = MaterialTheme.typography.bodyLarge, color = MiniColor.primary)
                    Text(MiniCopy.modeAppsCount(packages.size), style = MaterialTheme.typography.labelMedium, color = MiniColor.muted, modifier = Modifier.padding(top = 4.dp))
                }
            }
            Text(MiniCopy.modePrivacyNote, style = MaterialTheme.typography.labelMedium, color = MiniColor.muted)

            if (isEditing) {
                TextButton(
                    onClick = {
                        val active = viewModel.focus.value.activeMode?.id == existing!!.id
                        if (active) showActiveDeleteAlert = true else showDeleteConfirm = true
                    },
                ) { Text(MiniCopy.modeDelete, color = MiniColor.error) }
            }
        }
    }

    if (showIconPicker) {
        IconPickerDialog(
            current = icon,
            onPick = { icon = it; showIconPicker = false },
            onDismiss = { showIconPicker = false },
        )
    }

    if (showAppPicker) {
        val context = LocalContext.current
        AppPickerDialog(
            initiallySelected = packages,
            loadApps = { InstalledApps.query(context) },
            onConfirm = { packages = it; showAppPicker = false },
            onDismiss = { showAppPicker = false },
        )
    }

    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text(MiniCopy.modeDeleteTitle) },
            text = { Text(MiniCopy.modeDeleteBody) },
            confirmButton = {
                TextButton(onClick = {
                    showDeleteConfirm = false
                    existing?.let { viewModel.deleteMode(it.id) { ok -> if (ok) onClose() } }
                }) { Text(MiniCopy.actionDelete, color = MiniColor.error) }
            },
            dismissButton = { TextButton(onClick = { showDeleteConfirm = false }) { Text(MiniCopy.actionCancel) } },
        )
    }

    if (showActiveDeleteAlert) {
        AlertDialog(
            onDismissRequest = { showActiveDeleteAlert = false },
            title = { Text(MiniCopy.modeActiveDeleteTitle) },
            text = { Text(MiniCopy.modeActiveDeleteBody) },
            confirmButton = { TextButton(onClick = { showActiveDeleteAlert = false }) { Text(MiniCopy.actionOK) } },
        )
    }
}

private const val Mode_DEFAULT_ICON = "notifications_off"

package app.minifocus.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import app.minifocus.nfc.BROKE_MARKER
import app.minifocus.nfc.NfcException
import app.minifocus.ui.LocalNfcService
import app.minifocus.ui.MainViewModel
import app.minifocus.ui.MiniCard
import app.minifocus.ui.MiniCopy
import app.minifocus.ui.MiniSecondaryButton
import app.minifocus.ui.NfcProgressDialog
import app.minifocus.ui.theme.MiniColor
import app.minifocus.ui.theme.MiniSpacing
import kotlinx.coroutines.launch
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import java.util.UUID

/** Edit a connected Mini Tag: rename, (re)assign Mode, write marker, delete. Mirrors iOS `TagDetailView`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TagDetailScreen(
    viewModel: MainViewModel,
    tagId: UUID,
    onClose: () -> Unit,
) {
    val tags by viewModel.tags.collectAsState()
    val modes by viewModel.modes.collectAsState()
    val tag = remember(tags, tagId) { tags.firstOrNull { it.id == tagId } }
    val nfc = LocalNfcService.current
    val scope = rememberCoroutineScope()

    if (tag == null) {
        // Tag was removed; close.
        onClose()
        return
    }

    var name by remember(tag.id) { mutableStateOf(tag.name) }
    var scanning by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }
    var showDeleteConfirm by remember { mutableStateOf(false) }

    fun persistName() {
        val trimmed = name.trim()
        if (trimmed.isNotEmpty() && trimmed != tag.name) viewModel.renameTag(tag, trimmed)
    }

    Scaffold(
        containerColor = MiniColor.background,
        topBar = {
            TopAppBar(
                title = { Text(tag.name) },
                navigationIcon = {
                    IconButton(onClick = { persistName(); onClose() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = MiniCopy.actionDone)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MiniColor.background, titleContentColor = MiniColor.text),
            )
        },
    ) { inner ->
        Column(
            modifier = Modifier.padding(inner).fillMaxSize().padding(horizontal = MiniSpacing.horizontal, vertical = MiniSpacing.md),
            verticalArrangement = Arrangement.spacedBy(MiniSpacing.md),
        ) {
            Text(MiniCopy.tagNameSection, style = MaterialTheme.typography.labelMedium, color = MiniColor.muted)
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                placeholder = { Text(MiniCopy.tagNamePlaceholder) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )

            Text(MiniCopy.tagModeSection, style = MaterialTheme.typography.labelMedium, color = MiniColor.muted)
            MiniCard {
                ModePickerField(
                    modes = modes,
                    selectedModeId = tag.linkedModeId,
                    onSelect = { viewModel.setTagMode(tag, it) },
                )
            }

            Text(MiniCopy.tagInfoSection, style = MaterialTheme.typography.labelMedium, color = MiniColor.muted)
            MiniCard {
                Column(verticalArrangement = Arrangement.spacedBy(MiniSpacing.xs)) {
                    InfoRow(MiniCopy.tagIdentifier, tag.hardwareIdentifier ?: MiniCopy.tagIdentifierUnknown)
                    val registered = remember(tag.createdAt) {
                        DateTimeFormatter.ofPattern("dd/MM/yyyy", Locale.getDefault())
                            .withZone(ZoneId.systemDefault())
                            .format(tag.createdAt)
                    }
                    InfoRow(MiniCopy.tagRegistered, registered)
                }
            }

            MiniSecondaryButton(text = MiniCopy.tagWrite, onClick = {
                if (!nfc.isAvailable) {
                    message = MiniCopy.nfcUnavailable
                } else {
                    scanning = true
                    scope.launch {
                        try {
                            nfc.write(BROKE_MARKER)
                            message = MiniCopy.tagWriteSuccess
                        } catch (e: NfcException) {
                            if (e !is NfcException.Cancelled) message = MiniCopy.tagWriteError(e.message ?: "")
                        } finally {
                            scanning = false
                        }
                    }
                }
            })

            TextButton(onClick = { showDeleteConfirm = true }) {
                Text(MiniCopy.tagDelete, color = MiniColor.error)
            }
        }
    }

    if (scanning) NfcProgressDialog(onCancel = { nfc.cancel() })

    message?.let { text ->
        AlertDialog(
            onDismissRequest = { message = null },
            text = { Text(text) },
            confirmButton = { TextButton(onClick = { message = null }) { Text(MiniCopy.actionOK) } },
        )
    }

    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text(MiniCopy.tagDeleteTitle) },
            text = { Text(MiniCopy.tagDeleteBody) },
            confirmButton = {
                TextButton(onClick = {
                    showDeleteConfirm = false
                    viewModel.deleteTag(tag.id) { onClose() }
                }) { Text(MiniCopy.actionRemove, color = MiniColor.error) }
            },
            dismissButton = { TextButton(onClick = { showDeleteConfirm = false }) { Text(MiniCopy.actionCancel) } },
        )
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MiniColor.muted, modifier = Modifier.weight(1f))
        Text(value, style = MaterialTheme.typography.bodyMedium, color = MiniColor.text)
    }
}

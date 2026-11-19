package app.minifocus.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
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
import app.minifocus.ui.LocalNfcService
import app.minifocus.ui.MainViewModel
import app.minifocus.ui.MiniCard
import app.minifocus.ui.MiniCopy
import app.minifocus.ui.MiniSecondaryButton
import app.minifocus.ui.NfcProgressDialog
import app.minifocus.ui.theme.MiniColor
import app.minifocus.ui.theme.MiniSpacing
import app.minifocus.nfc.NfcException
import kotlinx.coroutines.launch
import java.util.UUID

/** Connect a new Mini Tag: scan, name and optionally link a Mode. Mirrors iOS `TagPairingView`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TagPairingScreen(
    viewModel: MainViewModel,
    prefilledUid: String?,
    onClose: () -> Unit,
) {
    val modes by viewModel.modes.collectAsState()
    val tags by viewModel.tags.collectAsState()
    val nfc = LocalNfcService.current
    val scope = rememberCoroutineScope()

    var hardwareIdentifier by remember { mutableStateOf(prefilledUid) }
    var name by remember { mutableStateOf("") }
    var linkedModeId by remember { mutableStateOf<UUID?>(null) }
    var scanning by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val alreadyName = hardwareIdentifier?.let { uid -> tags.firstOrNull { it.hardwareIdentifier == uid }?.name }
    val canSave = name.trim().isNotEmpty()

    fun scan() {
        if (!nfc.isAvailable) { errorMessage = MiniCopy.nfcUnavailable; return }
        scanning = true
        scope.launch {
            try {
                val scanned = nfc.scan()
                hardwareIdentifier = scanned.hardwareIdentifier
            } catch (e: NfcException) {
                if (e !is NfcException.Cancelled) errorMessage = e.message
            } finally {
                scanning = false
            }
        }
    }

    Scaffold(
        containerColor = MiniColor.background,
        topBar = {
            TopAppBar(
                title = { Text(MiniCopy.pairingTitle) },
                navigationIcon = { IconButton(onClick = onClose) { Icon(Icons.Filled.Close, contentDescription = MiniCopy.actionCancel) } },
                actions = {
                    TextButton(enabled = canSave, onClick = {
                        viewModel.registerTag(
                            hardwareIdentifier = hardwareIdentifier,
                            name = name.trim(),
                            linkedModeId = linkedModeId,
                            onDone = onClose,
                            onError = { errorMessage = MiniCopy.pairingRegisterError(it) },
                        )
                    }) { Text(MiniCopy.actionSave) }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MiniColor.background, titleContentColor = MiniColor.text),
            )
        },
    ) { inner ->
        Column(
            modifier = Modifier.padding(inner).fillMaxSize().padding(horizontal = MiniSpacing.horizontal, vertical = MiniSpacing.md),
            verticalArrangement = Arrangement.spacedBy(MiniSpacing.md),
        ) {
            Text(MiniCopy.pairingTagSection, style = MaterialTheme.typography.labelMedium, color = MiniColor.muted)
            MiniCard {
                Column(verticalArrangement = Arrangement.spacedBy(MiniSpacing.xs)) {
                    hardwareIdentifier?.let { uid ->
                        Text(uid, style = MaterialTheme.typography.bodyLarge, color = MiniColor.text)
                        alreadyName?.let { Text(MiniCopy.pairingAlready(it), style = MaterialTheme.typography.labelMedium, color = MiniColor.warm) }
                    }
                    MiniSecondaryButton(text = if (scanning) MiniCopy.pairingScanning else MiniCopy.pairingScan, onClick = { scan() })
                }
            }

            Text(MiniCopy.pairingNameSection, style = MaterialTheme.typography.labelMedium, color = MiniColor.muted)
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                placeholder = { Text(MiniCopy.pairingNamePlaceholder) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )

            Text(MiniCopy.pairingModeSection, style = MaterialTheme.typography.labelMedium, color = MiniColor.muted)
            MiniCard {
                ModePickerField(modes = modes, selectedModeId = linkedModeId, onSelect = { linkedModeId = it })
            }
        }
    }

    if (scanning) NfcProgressDialog(onCancel = { nfc.cancel() })

    errorMessage?.let { message ->
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { errorMessage = null },
            title = { Text(MiniCopy.nfcErrorTitle) },
            text = { Text(message) },
            confirmButton = { TextButton(onClick = { errorMessage = null }) { Text(MiniCopy.actionOK) } },
        )
    }
}

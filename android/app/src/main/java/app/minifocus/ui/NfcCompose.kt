package app.minifocus.ui

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.DialogProperties
import app.minifocus.nfc.NfcService
import androidx.compose.runtime.staticCompositionLocalOf

/** Provides the activity-scoped [NfcService] to the Compose tree. */
val LocalNfcService = staticCompositionLocalOf<NfcService> {
    error("No NfcService provided")
}

/**
 * A simple "hold your phone near the Mini Tag" progress dialog shown while an
 * NFC read/write is in flight. Cancelling invokes [onCancel], which should call
 * [NfcService.cancel].
 */
@Composable
fun NfcProgressDialog(
    message: String = MiniCopy.nfcScanning,
    onCancel: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onCancel,
        properties = DialogProperties(dismissOnClickOutside = false),
        title = { Text(MiniCopy.nfcScanPrompt) },
        text = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                CircularProgressIndicator(modifier = Modifier.size(24.dp))
                Text(text = message, modifier = Modifier.padding(start = 12.dp))
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onCancel) { Text(MiniCopy.actionCancel) }
        },
    )
}

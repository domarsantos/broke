package app.minifocus.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.outlined.TrackChanges
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.minifocus.domain.FocusSession
import app.minifocus.domain.Mode
import app.minifocus.focus.FocusOutcome
import app.minifocus.nfc.NfcException
import app.minifocus.nfc.ScannedTag
import app.minifocus.ui.LocalNfcService
import app.minifocus.ui.MiniCard
import app.minifocus.ui.MiniCopy
import app.minifocus.ui.MiniPrimaryButton
import app.minifocus.ui.MiniQuietButton
import app.minifocus.ui.MiniSecondaryButton
import app.minifocus.ui.MiniStatusMark
import app.minifocus.ui.MainViewModel
import app.minifocus.ui.ModeIcons
import app.minifocus.ui.NfcProgressDialog
import app.minifocus.ui.theme.MiniColor
import app.minifocus.ui.theme.MiniSpacing
import kotlinx.coroutines.launch
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * The "Hoje" screen: current focus state and the single CTA to read the Mini
 * Tag. All activation logic lives in [MainViewModel]/[FocusController]; this
 * view contains no NFC or blocking business rules. Mirrors iOS `TodayView`.
 */
@Composable
fun TodayScreen(
    viewModel: MainViewModel,
    onPairNeeded: (ScannedTag) -> Unit,
) {
    val focus by viewModel.focus.collectAsState()
    val modes by viewModel.modes.collectAsState()
    val isAuthorized by viewModel.isAuthorized.collectAsState()
    val nfc = LocalNfcService.current
    val scope = rememberCoroutineScope()

    var scanning by remember { mutableStateOf(false) }
    var showNoModeAlert by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val isBlocking = focus.isActive
    val hasModes = modes.isNotEmpty()

    fun scanTag() {
        if (!nfc.isAvailable) {
            errorMessage = MiniCopy.nfcUnavailable
            return
        }
        scanning = true
        scope.launch {
            try {
                val scanned = nfc.scan()
                when (val outcome = viewModel.handleScan(scanned)) {
                    is FocusOutcome.Unregistered -> onPairNeeded(outcome.scanned)
                    is FocusOutcome.NoModeToActivate -> showNoModeAlert = true
                    else -> Unit // state updates drive the UI
                }
            } catch (e: NfcException) {
                if (e !is NfcException.Cancelled) errorMessage = describe(e)
            } catch (e: Exception) {
                errorMessage = e.message
            } finally {
                scanning = false
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = MiniSpacing.horizontal)
            .padding(top = MiniSpacing.xl, bottom = MiniSpacing.section),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(MiniSpacing.section),
    ) {
        Text(
            text = MiniCopy.tagline,
            style = MaterialTheme.typography.labelMedium,
            color = MiniColor.muted,
            textAlign = TextAlign.Center,
        )

        if (!isAuthorized) {
            PermissionCard(onAuthorize = viewModel::openAuthorizationSettings)
        }

        StatusBlock(isBlocking = isBlocking, hasModes = hasModes, focusMode = focus.activeMode, session = focus.activeSession)

        Column(
            modifier = Modifier.widthIn(max = 520.dp).fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(MiniSpacing.sm),
        ) {
            MiniPrimaryButton(
                text = if (isBlocking) MiniCopy.homeOnCTA else MiniCopy.homeOffCTA,
                onClick = { scanTag() },
            )
            if (!isBlocking) {
                MiniQuietButton(text = MiniCopy.homeStartWithoutTag) {
                    scope.launch {
                        if (!viewModel.startWithoutTag()) showNoModeAlert = true
                    }
                }
            }
        }
    }

    if (scanning) {
        NfcProgressDialog(onCancel = { nfc.cancel() })
    }

    if (showNoModeAlert) {
        AlertDialog(
            onDismissRequest = { showNoModeAlert = false },
            title = { Text(MiniCopy.noModeTitle) },
            text = { Text(MiniCopy.noModeBody) },
            confirmButton = { TextButton(onClick = { showNoModeAlert = false }) { Text(MiniCopy.actionOK) } },
        )
    }

    errorMessage?.let { message ->
        AlertDialog(
            onDismissRequest = { errorMessage = null },
            title = { Text(MiniCopy.nfcErrorTitle) },
            text = { Text(message) },
            confirmButton = { TextButton(onClick = { errorMessage = null }) { Text(MiniCopy.actionOK) } },
        )
    }
}

@Composable
private fun StatusBlock(
    isBlocking: Boolean,
    hasModes: Boolean,
    focusMode: Mode?,
    session: FocusSession?,
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(MiniSpacing.md),
    ) {
        MiniStatusMark(
            icon = if (isBlocking) Icons.Outlined.TrackChanges else Icons.Filled.Bedtime,
            title = if (isBlocking) MiniCopy.homeOnTitle else if (hasModes) MiniCopy.homeOffTitle else MiniCopy.homePrepareTitle,
        )
        Text(
            text = if (isBlocking) MiniCopy.homeOnBody else if (hasModes) MiniCopy.homeOffBody else MiniCopy.homePrepareBody,
            style = MaterialTheme.typography.bodyLarge,
            color = MiniColor.muted,
            textAlign = TextAlign.Center,
        )
        if (isBlocking && focusMode != null && session != null) {
            ActiveModeCard(mode = focusMode, session = session)
        }
    }
}

@Composable
private fun ActiveModeCard(mode: Mode, session: FocusSession) {
    val time = remember(session.startedAt) {
        DateTimeFormatter.ofPattern("HH:mm", Locale.getDefault())
            .withZone(ZoneId.systemDefault())
            .format(session.startedAt)
    }
    MiniCard(fill = MiniColor.sage) {
        androidx.compose.foundation.layout.Row(verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = CircleShape, color = MiniColor.surface, modifier = Modifier.size(44.dp)) {
                androidx.compose.foundation.layout.Box(contentAlignment = Alignment.Center) {
                    Icon(ModeIcons.icon(mode.icon), contentDescription = null, tint = MiniColor.primary, modifier = Modifier.size(22.dp))
                }
            }
            Column(modifier = Modifier.padding(start = MiniSpacing.md)) {
                Text(mode.name, style = MaterialTheme.typography.labelLarge, color = MiniColor.text)
                Text(MiniCopy.homeActiveSince(time), style = MaterialTheme.typography.labelMedium, color = MiniColor.muted)
            }
        }
    }
}

@Composable
private fun PermissionCard(onAuthorize: () -> Unit) {
    MiniCard {
        Column(verticalArrangement = Arrangement.spacedBy(MiniSpacing.sm)) {
            androidx.compose.foundation.layout.Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Lock, contentDescription = null, tint = MiniColor.text, modifier = Modifier.size(20.dp))
                Text(
                    MiniCopy.permissionTitle,
                    style = MaterialTheme.typography.labelLarge,
                    color = MiniColor.text,
                    modifier = Modifier.padding(start = MiniSpacing.xs),
                )
            }
            Text(MiniCopy.permissionBody, style = MaterialTheme.typography.labelMedium, color = MiniColor.muted)
            MiniSecondaryButton(text = MiniCopy.permissionCTA, onClick = onAuthorize)
        }
    }
}

private fun describe(error: NfcException): String = when (error) {
    is NfcException.Unavailable -> MiniCopy.nfcUnavailable
    is NfcException.NoTag -> MiniCopy.nfcNoTag
    is NfcException.ReadFailed -> error.message ?: MiniCopy.nfcReadFailedGeneric
    is NfcException.WriteFailed -> error.message ?: MiniCopy.nfcWriteFailedGeneric
    is NfcException.Cancelled -> ""
}

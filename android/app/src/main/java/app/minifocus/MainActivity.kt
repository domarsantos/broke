package app.minifocus

import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import app.minifocus.focus.FocusOutcome
import app.minifocus.nfc.AndroidNfcService
import app.minifocus.nfc.NfcService
import app.minifocus.nfc.ScannedTag
import app.minifocus.nfc.toHexUpper
import app.minifocus.ui.LocalNfcService
import app.minifocus.ui.MainViewModel
import app.minifocus.ui.MiniCopy
import app.minifocus.ui.RootScaffold
import app.minifocus.ui.theme.MiniFocusTheme
import androidx.compose.runtime.CompositionLocalProvider
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    private lateinit var nfc: NfcService
    private lateinit var viewModel: MainViewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val container = (application as MiniFocusApp).container
        nfc = AndroidNfcService(this)
        viewModel = ViewModelProvider(
            this,
            MainViewModel.Factory(application, container),
        )[MainViewModel::class.java]

        setContent {
            MiniFocusTheme {
                CompositionLocalProvider(LocalNfcService provides nfc) {
                    RootScaffold(viewModel)
                }
            }
        }

        handleNfcIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        viewModel.refreshAuthorization()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleNfcIntent(intent)
    }

    /**
     * Handle a tag that launched the app (a Mini Tag already written with the
     * BROKE-IS-GREAT marker). The in-app "Ler Mini Tag" button uses reader mode
     * instead; this only covers the system NDEF_DISCOVERED path.
     */
    private fun handleNfcIntent(intent: Intent?) {
        if (intent?.action != NfcAdapter.ACTION_NDEF_DISCOVERED) return
        val scanned = intent.toScannedTag() ?: return
        lifecycleScope.launch {
            when (viewModel.handleScan(scanned)) {
                is FocusOutcome.Unregistered ->
                    toast(MiniCopy.tagUnknownTitle)
                is FocusOutcome.NoModeToActivate ->
                    toast(MiniCopy.noModeBody)
                else -> Unit // activate/deactivate/switch reflected in the UI
            }
        }
    }

    private fun toast(text: String) {
        Toast.makeText(this, text, Toast.LENGTH_SHORT).show()
    }
}

@Suppress("DEPRECATION")
private fun Intent.toScannedTag(): ScannedTag? {
    val tag: Tag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        getParcelableExtra(NfcAdapter.EXTRA_TAG, Tag::class.java)
    } else {
        getParcelableExtra(NfcAdapter.EXTRA_TAG)
    } ?: return null

    val uid = tag.id?.toHexUpper() ?: return null

    val messages: Array<NdefMessage>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES, NdefMessage::class.java)
    } else {
        @Suppress("UNCHECKED_CAST")
        (getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES) as? Array<NdefMessage>)
    }

    val text = messages?.firstOrNull()?.records?.firstOrNull()?.let { record ->
        runCatching {
            val payload = record.payload
            if (payload.isEmpty()) return@let null
            val status = payload[0].toInt()
            val isUtf16 = status and 0x80 != 0
            val languageLength = status and 0x3F
            val start = 1 + languageLength
            if (start > payload.size) return@let null
            String(payload, start, payload.size - start, if (isUtf16) Charsets.UTF_16 else Charsets.UTF_8)
        }.getOrNull()
    }

    return ScannedTag(hardwareIdentifier = uid, ndefText = text)
}

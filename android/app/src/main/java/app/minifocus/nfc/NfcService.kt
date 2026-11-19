package app.minifocus.nfc

import android.nfc.FormatException
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.nfc.tech.NdefFormatable
import androidx.activity.ComponentActivity
import app.minifocus.ui.MiniCopy
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * The text payload written to tags so the same physical Mini Tag recognised on
 * iOS is also recognised here (and vice-versa).
 */
const val BROKE_MARKER = "BROKE-IS-GREAT"

/** Errors surfaced by [NfcService], mirroring iOS `NFCServiceError`. */
sealed class NfcException(message: String) : Exception(message) {
    data object Unavailable : NfcException("NFC unavailable")
    data object Cancelled : NfcException("Cancelled")
    data object NoTag : NfcException("No tag")
    class ReadFailed(message: String) : NfcException(message)
    class WriteFailed(message: String) : NfcException(message)
}

/**
 * Isolates all NFC complexity. The rest of the app only sees [ScannedTag] and
 * this API. Faithful counterpart of iOS' `NFCService`: it reads the tag's
 * physical UID (upper-case hex) and the NDEF text payload on the same session,
 * and can write the text payload.
 */
interface NfcService {
    val isAvailable: Boolean
    suspend fun scan(): ScannedTag
    suspend fun write(text: String): ScannedTag
    fun cancel()
}

/**
 * Reader-mode based implementation tied to the foreground [activity]. Reader
 * mode must be toggled while the activity is resumed, which is exactly when the
 * UI invokes [scan]/[write].
 */
class AndroidNfcService(private val activity: ComponentActivity) : NfcService {

    private val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(activity)
    private var deferred: CompletableDeferred<ScannedTag>? = null
    private var textToWrite: String? = null

    override val isAvailable: Boolean
        get() = adapter?.isEnabled == true

    override suspend fun scan(): ScannedTag {
        textToWrite = null
        return runSession()
    }

    override suspend fun write(text: String): ScannedTag {
        textToWrite = text
        return runSession()
    }

    override fun cancel() {
        deferred?.completeExceptionally(NfcException.Cancelled)
    }

    private suspend fun runSession(): ScannedTag {
        val a = adapter ?: throw NfcException.Unavailable
        if (!a.isEnabled) throw NfcException.Unavailable

        val d = CompletableDeferred<ScannedTag>()
        deferred = d

        val flags = NfcAdapter.FLAG_READER_NFC_A or
            NfcAdapter.FLAG_READER_NFC_B or
            NfcAdapter.FLAG_READER_NFC_F or
            NfcAdapter.FLAG_READER_NFC_V or
            NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS

        withContext(Dispatchers.Main) {
            a.enableReaderMode(activity, { tag -> onTagDiscovered(tag) }, flags, null)
        }

        try {
            return d.await()
        } finally {
            withContext(Dispatchers.Main) { a.disableReaderMode(activity) }
            deferred = null
            textToWrite = null
        }
    }

    private fun onTagDiscovered(tag: Tag) {
        val d = deferred ?: return
        val identifier = tag.id.toHexUpper()
        val toWrite = textToWrite
        try {
            if (toWrite != null) {
                writeText(tag, toWrite)
                d.complete(ScannedTag(hardwareIdentifier = identifier, ndefText = toWrite))
            } else {
                val text = readText(tag)
                d.complete(ScannedTag(hardwareIdentifier = identifier, ndefText = text))
            }
        } catch (e: Exception) {
            if (toWrite != null) {
                d.completeExceptionally(NfcException.WriteFailed(e.message ?: MiniCopy.nfcWriteFailedGeneric))
            } else {
                d.completeExceptionally(NfcException.ReadFailed(e.message ?: MiniCopy.nfcReadFailedGeneric))
            }
        }
    }

    // MARK: - NDEF read/write

    private fun readText(tag: Tag): String? {
        val ndef = Ndef.get(tag) ?: return null
        return try {
            ndef.connect()
            val message = ndef.cachedNdefMessage ?: runCatching { ndef.ndefMessage }.getOrNull()
            message?.let { firstText(it) }
        } finally {
            runCatching { ndef.close() }
        }
    }

    private fun writeText(tag: Tag, text: String) {
        val message = NdefMessage(arrayOf(NdefRecord.createTextRecord("en", text)))

        val ndef = Ndef.get(tag)
        if (ndef != null) {
            ndef.connect()
            try {
                if (!ndef.isWritable) throw NfcException.WriteFailed(MiniCopy.nfcReadOnly)
                if (ndef.maxSize < message.toByteArray().size) {
                    throw NfcException.WriteFailed(MiniCopy.nfcBuildPayload)
                }
                ndef.writeNdefMessage(message)
            } finally {
                runCatching { ndef.close() }
            }
            return
        }

        val formatable = NdefFormatable.get(tag)
            ?: throw NfcException.WriteFailed(MiniCopy.nfcNotCompliant)
        formatable.connect()
        try {
            formatable.format(message)
        } catch (e: FormatException) {
            throw NfcException.WriteFailed(e.message ?: MiniCopy.nfcBuildPayload)
        } finally {
            runCatching { formatable.close() }
        }
    }

    private fun firstText(message: NdefMessage): String? {
        for (record in message.records) {
            if (record.tnf == NdefRecord.TNF_WELL_KNOWN &&
                record.type.contentEquals(NdefRecord.RTD_TEXT)
            ) {
                return decodeTextRecord(record)
            }
            if (record.tnf == NdefRecord.TNF_WELL_KNOWN &&
                record.type.contentEquals(NdefRecord.RTD_URI)
            ) {
                return record.toUri()?.toString()
            }
        }
        return null
    }

    private fun decodeTextRecord(record: NdefRecord): String? {
        val payload = record.payload
        if (payload.isEmpty()) return null
        val status = payload[0].toInt()
        val isUtf16 = status and 0x80 != 0
        val languageLength = status and 0x3F
        val textStart = 1 + languageLength
        if (textStart > payload.size) return null
        val charset = if (isUtf16) Charsets.UTF_16 else Charsets.UTF_8
        return String(payload, textStart, payload.size - textStart, charset)
    }
}

/** Core NFC counterpart of the iOS hex UID extraction. */
fun ByteArray.toHexUpper(): String = joinToString("") { "%02X".format(it) }

/** Build a [ScannedTag] from a raw UID and optional NDEF text. */
fun scannedTagFrom(uid: ByteArray, ndefText: String?): ScannedTag =
    ScannedTag(hardwareIdentifier = uid.toHexUpper(), ndefText = ndefText)

package app.minifocus.nfc

/**
 * The result of scanning a physical tag. Mirrors the iOS `ScannedTag`.
 */
data class ScannedTag(
    /** Upper-case hex physical UID (e.g. "04A1B2C3D4E5F6"). */
    val hardwareIdentifier: String,
    /** NDEF text payload if present (used to recognise "BROKE-IS-GREAT" tags). */
    val ndefText: String?,
)

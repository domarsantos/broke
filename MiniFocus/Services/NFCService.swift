//
//  NFCService.swift
//  MiniFocus
//
//  Isolates ALL Core NFC complexity. The rest of the app only sees
//  `ScannedTag` and the `NFCServiceProtocol` API.
//
//  Unlike v0.1 (which used NFCNDEFReaderSession and could only read the NDEF
//  text payload), this uses NFCTagReaderSession so we can read the tag's
//  physical UID (hardware identifier) for NTAG213 / MIFARE-compatible tags,
//  while still reading and writing the NDEF text payload on the same session.
//

import Foundation
import CoreNFC

/// The result of scanning a physical tag.
struct ScannedTag: Equatable {
    /// Hex-encoded physical UID (e.g. "04A1B2C3D4E5F6"). Empty only if the
    /// hardware did not expose one, which is rare for supported tags.
    let hardwareIdentifier: String
    /// NDEF text payload if present (used to recognise legacy "BROKE-IS-GREAT" tags).
    let ndefText: String?
}

enum NFCServiceError: Error, Equatable {
    case unavailable
    case cancelled
    case readFailed(String)
    case writeFailed(String)
    case noTag
}

protocol NFCServiceProtocol {
    var isAvailable: Bool { get }
    /// Scan a tag and return its physical identifier (and NDEF text if any).
    func scan() async throws -> ScannedTag
    /// Write NDEF text to a tag and return its identifier.
    func write(text: String) async throws -> ScannedTag
}

final class NFCService: NSObject, NFCServiceProtocol {
    private var session: NFCTagReaderSession?
    private var continuation: CheckedContinuation<ScannedTag, Error>?
    private var textToWrite: String?

    var isAvailable: Bool { NFCTagReaderSession.readingAvailable }

    func scan() async throws -> ScannedTag {
        textToWrite = nil
        return try await runSession(alert: MiniCopy.nfcScanPrompt)
    }

    func write(text: String) async throws -> ScannedTag {
        textToWrite = text
        return try await runSession(alert: MiniCopy.nfcWritePrompt)
    }

    private func runSession(alert: String) async throws -> ScannedTag {
        guard isAvailable else { throw NFCServiceError.unavailable }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self, queue: nil)
            session?.alertMessage = alert
            self.session = session
            session?.begin()
        }
    }

    /// Resume the continuation exactly once.
    private func finish(_ result: Result<ScannedTag, Error>) {
        guard let continuation = continuation else { return }
        self.continuation = nil
        self.textToWrite = nil
        self.session = nil
        continuation.resume(with: result)
    }

    // MARK: - UID extraction

    private static func hexIdentifier(for tag: NFCTag) -> String {
        let data: Data
        switch tag {
        case let .miFare(t): data = t.identifier
        case let .iso7816(t): data = t.identifier
        case let .iso15693(t): data = t.identifier
        case let .feliCa(t): data = t.currentIDm
        @unknown default: data = Data()
        }
        return data.map { String(format: "%02X", $0) }.joined()
    }

    private static func ndefTag(from tag: NFCTag) -> NFCNDEFTag? {
        switch tag {
        case let .miFare(t): return t
        case let .iso7816(t): return t
        case let .iso15693(t): return t
        case let .feliCa(t): return t
        @unknown default: return nil
        }
    }
}

// MARK: - NFCTagReaderSessionDelegate

extension NFCService: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError,
           readerError.code == .readerSessionInvalidationErrorUserCanceled {
            finish(.failure(NFCServiceError.cancelled))
        } else {
            finish(.failure(NFCServiceError.readFailed(error.localizedDescription)))
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if tags.count > 1 {
            session.alertMessage = MiniCopy.nfcMultipleTags
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                session.restartPolling()
            }
            return
        }

        guard let tag = tags.first else {
            session.invalidate(errorMessage: MiniCopy.nfcNoTagDetected)
            return
        }

        let identifier = Self.hexIdentifier(for: tag)

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            if let error {
                session.invalidate(errorMessage: MiniCopy.nfcConnectionError(error.localizedDescription))
                return
            }

            guard let ndefTag = Self.ndefTag(from: tag) else {
                // No NDEF support, but we still have the UID.
                session.alertMessage = MiniCopy.nfcTagRead
                session.invalidate()
                self.finish(.success(ScannedTag(hardwareIdentifier: identifier, ndefText: nil)))
                return
            }

            if let textToWrite = self.textToWrite {
                self.writeNDEF(text: textToWrite, to: ndefTag, identifier: identifier, session: session)
            } else {
                self.readNDEF(from: ndefTag, identifier: identifier, session: session)
            }
        }
    }

    private func readNDEF(from tag: NFCNDEFTag, identifier: String, session: NFCTagReaderSession) {
        tag.queryNDEFStatus { [weak self] status, _, error in
            guard let self else { return }
            if error != nil || status == .notSupported {
                // Not NDEF-formatted; UID is still valid.
                session.alertMessage = MiniCopy.nfcTagRead
                session.invalidate()
                self.finish(.success(ScannedTag(hardwareIdentifier: identifier, ndefText: nil)))
                return
            }

            tag.readNDEF { message, _ in
                let text = message.flatMap { Self.firstText(in: $0) }
                session.alertMessage = MiniCopy.nfcTagRead
                session.invalidate()
                self.finish(.success(ScannedTag(hardwareIdentifier: identifier, ndefText: text)))
            }
        }
    }

    private func writeNDEF(text: String, to tag: NFCNDEFTag, identifier: String, session: NFCTagReaderSession) {
        tag.queryNDEFStatus { [weak self] status, _, error in
            guard let self else { return }
            if let error {
                session.invalidate(errorMessage: MiniCopy.nfcQueryFailed(error.localizedDescription))
                self.finish(.failure(NFCServiceError.writeFailed(error.localizedDescription)))
                return
            }
            switch status {
            case .notSupported:
                session.invalidate(errorMessage: MiniCopy.nfcNotCompliant)
                self.finish(.failure(NFCServiceError.writeFailed(MiniCopy.nfcNotCompliant)))
            case .readOnly:
                session.invalidate(errorMessage: MiniCopy.nfcReadOnly)
                self.finish(.failure(NFCServiceError.writeFailed(MiniCopy.nfcReadOnly)))
            case .readWrite:
                guard let payload = NFCNDEFPayload.wellKnownTypeTextPayload(string: text, locale: Locale(identifier: "en")) else {
                    session.invalidate(errorMessage: MiniCopy.nfcBuildPayload)
                    self.finish(.failure(NFCServiceError.writeFailed(MiniCopy.nfcBuildPayload)))
                    return
                }
                let message = NFCNDEFMessage(records: [payload])
                tag.writeNDEF(message) { error in
                    if let error {
                        session.invalidate(errorMessage: MiniCopy.nfcWriteFailed(error.localizedDescription))
                        self.finish(.failure(NFCServiceError.writeFailed(error.localizedDescription)))
                    } else {
                        session.alertMessage = MiniCopy.nfcTagWritten
                        session.invalidate()
                        self.finish(.success(ScannedTag(hardwareIdentifier: identifier, ndefText: text)))
                    }
                }
            @unknown default:
                session.invalidate(errorMessage: MiniCopy.nfcUnknownStatus)
                self.finish(.failure(NFCServiceError.writeFailed(MiniCopy.nfcUnknownStatus)))
            }
        }
    }

    private static func firstText(in message: NFCNDEFMessage) -> String? {
        for record in message.records {
            if record.typeNameFormat == .nfcWellKnown,
               let text = record.wellKnownTypeTextPayload().0 {
                return text
            }
            if let url = record.wellKnownTypeURIPayload() {
                return url.absoluteString
            }
        }
        return nil
    }
}

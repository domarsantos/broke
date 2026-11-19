//
//  FocusController.swift
//  MiniFocus
//
//  The single source of truth for the active focus session. It owns the
//  domain rules execution, session persistence and Screen Time application.
//  Views call into this; they never touch repositories, rules, NFC or
//  ManagedSettings directly for activation logic.
//

import Foundation
import Observation

/// The user-visible result of handling a scan.
enum FocusOutcome: Equatable {
    case activated(Mode)
    case deactivated
    case switched(Mode)
    case unregistered(ScannedTag)
    case noModeToActivate
    /// The scan was understood but refused (e.g. a different-mode tag during a
    /// locked session). The running session is unchanged.
    case denied(FocusDenialReason)
}

@MainActor
@Observable
final class FocusController {
    private(set) var activeSession: FocusSession?
    private(set) var activeMode: Mode?

    @ObservationIgnored private let modeRepository: ModeRepositoryProtocol
    @ObservationIgnored private let tagRepository: TagRepositoryProtocol
    @ObservationIgnored private let sessionRepository: SessionRepositoryProtocol
    @ObservationIgnored private let screenTime: ScreenTimeServiceProtocol

    init(
        modeRepository: ModeRepositoryProtocol,
        tagRepository: TagRepositoryProtocol,
        sessionRepository: SessionRepositoryProtocol,
        screenTime: ScreenTimeServiceProtocol
    ) {
        self.modeRepository = modeRepository
        self.tagRepository = tagRepository
        self.sessionRepository = sessionRepository
        self.screenTime = screenTime
    }

    var isActive: Bool { activeSession?.isActive == true }

    /// True when a locked (Strict/Security) session is currently running.
    /// Views read this to freeze edit/tag-management flows while locked.
    var isLockedActive: Bool {
        isActive && (activeMode?.isNFCLocked ?? false)
    }

    // MARK: - Scan handling

    /// Resolve a scanned tag and apply the matching focus rule.
    @discardableResult
    func handleScan(_ scanned: ScannedTag, fallbackModeID: UUID?) throws -> FocusOutcome {
        let tag = try tagRepository.fetch(hardwareIdentifier: scanned.hardwareIdentifier)
        let action = FocusRules.action(
            tag: tag,
            activeSession: activeSession,
            activeMode: activeMode,
            fallbackModeID: fallbackModeID
        )

        switch action {
        case .unregistered:
            return .unregistered(scanned)
        case .noModeToActivate:
            return .noModeToActivate
        case let .denied(reason):
            return .denied(reason)
        case let .activate(modeID, tagID):
            let mode = try startSession(modeID: modeID, trigger: .nfc, tagID: tagID)
            return .activated(mode)
        case .deactivate:
            try stop()
            return .deactivated
        case let .switchTo(modeID, tagID):
            let mode = try switchSession(toModeID: modeID, tagID: tagID)
            return .switched(mode)
        }
    }

    // MARK: - Manual control

    /// Start a session manually (no tag). Only allowed when nothing is running.
    @discardableResult
    func startManual(modeID: UUID) throws -> Mode? {
        guard !isActive else { return nil }
        return try startSession(modeID: modeID, trigger: .manual, tagID: nil)
    }

    /// Stop the running session from the Mini (manual tap). Refused for locked
    /// Modes, which can only be ended with an authorized Mini Tag.
    func stopManual() throws {
        guard let mode = activeMode else { return }
        guard FocusRules.canStopManually(activeMode: mode) else {
            throw FocusControllerError.manualStopBlocked
        }
        try stop()
    }

    // MARK: - Lifecycle recovery

    /// Restore state after a cold launch. Reconciles the device restrictions
    /// with the persisted active session instead of blindly re-applying.
    func recover() {
        do {
            let active = try sessionRepository.fetchActive()
                .sorted { $0.startedAt > $1.startedAt }

            guard let current = active.first else {
                try? screenTime.reconcile(activeMode: nil)
                activeSession = nil
                activeMode = nil
                return
            }

            // End any stray extra active sessions (should not normally happen).
            for extra in active.dropFirst() {
                try endPersisted(extra)
            }

            guard let mode = try modeRepository.fetch(id: current.modeID) else {
                // Mode was deleted while a session was running: end and clear.
                try endPersisted(current)
                try? screenTime.reconcile(activeMode: nil)
                activeSession = nil
                activeMode = nil
                return
            }

            activeSession = current
            activeMode = mode
            try? screenTime.reconcile(activeMode: mode)
        } catch {
            NSLog("FocusController.recover failed: \(error)")
        }
    }

    // MARK: - Private

    @discardableResult
    private func startSession(modeID: UUID, trigger: FocusTrigger, tagID: UUID?) throws -> Mode {
        guard let mode = try modeRepository.fetch(id: modeID) else {
            throw FocusControllerError.modeNotFound
        }

        // Validation BEFORE touching persistence or ManagedSettings.
        if mode.isSecurityMode && mode.selectedApplications.isEmpty {
            throw FocusControllerError.securityModeNeedsApps
        }
        if mode.isNFCLocked {
            let tags = try tagRepository.fetchAll()
            guard FocusRules.canStartLockedMode(mode, availableTags: tags) else {
                throw FocusControllerError.lockedModeNeedsAuthorizedTag
            }
        }
        guard screenTime.isAuthorized else {
            throw FocusControllerError.notAuthorized
        }

        // Persist BEFORE applying so the state survives a crash, but roll the
        // session back if applying the restrictions fails (so we never persist
        // a Mode as active without its protection in place).
        let session = FocusSession(modeID: modeID, trigger: trigger, tagID: tagID)
        try sessionRepository.create(session)
        do {
            try screenTime.activate(mode)
        } catch {
            try? sessionRepository.delete(id: session.id)
            NSLog("FocusController.startSession: activate failed, rolled back session: \(error)")
            throw FocusControllerError.activationFailed
        }

        activeSession = session
        activeMode = mode
        return mode
    }

    private func stop() throws {
        guard let current = activeSession, let mode = activeMode else { return }
        // Remove restrictions FIRST and verify; only then mark the session
        // ended. If removal fails we keep the session active (not silently
        // "ended" while the device is still restricted).
        do {
            try screenTime.deactivate(mode)
        } catch {
            NSLog("FocusController.stop: deactivate failed: \(error)")
            throw FocusControllerError.deactivationFailed
        }
        try endPersisted(current)
        activeSession = nil
        activeMode = nil
    }

    @discardableResult
    private func switchSession(toModeID modeID: UUID, tagID: UUID?) throws -> Mode {
        // The current Mode is never locked here (the rules only yield .switchTo
        // for unlocked sessions). startSession's activate replaces the
        // restrictions atomically for the new Mode.
        if let current = activeSession {
            try endPersisted(current)
        }
        return try startSession(modeID: modeID, trigger: .nfc, tagID: tagID)
    }

    private func endPersisted(_ session: FocusSession) throws {
        var ended = session
        ended.endedAt = Date()
        ended.status = .completed
        try sessionRepository.update(ended)
    }
}

enum FocusControllerError: Error, Equatable {
    case modeNotFound
    /// Attempted to start a locked Mode with no authorized Mini Tag available.
    case lockedModeNeedsAuthorizedTag
    /// Attempted to start a Security Mode with no applications selected.
    case securityModeNeedsApps
    /// FamilyControls authorization is missing.
    case notAuthorized
    /// Applying the ManagedSettings restrictions failed (session rolled back).
    case activationFailed
    /// Removing the ManagedSettings restrictions failed (session kept active).
    case deactivationFailed
    /// A manual stop was attempted on a locked Mode.
    case manualStopBlocked
}

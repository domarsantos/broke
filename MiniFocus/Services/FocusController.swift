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

    // MARK: - Scan handling

    /// Resolve a scanned tag and apply the matching focus rule.
    @discardableResult
    func handleScan(_ scanned: ScannedTag, fallbackModeID: UUID?) throws -> FocusOutcome {
        let tag = try tagRepository.fetch(hardwareIdentifier: scanned.hardwareIdentifier)
        let action = FocusRules.action(
            tag: tag,
            activeSession: activeSession,
            fallbackModeID: fallbackModeID
        )

        switch action {
        case .unregistered:
            return .unregistered(scanned)
        case .noModeToActivate:
            return .noModeToActivate
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

    // MARK: - Lifecycle recovery

    /// Restore state after a cold launch. Reapplies shields for a running
    /// session, or clears them if nothing should be active.
    func recover() {
        do {
            let active = try sessionRepository.fetchActive()
                .sorted { $0.startedAt > $1.startedAt }

            guard let current = active.first else {
                screenTime.clearRestrictions()
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
                screenTime.clearRestrictions()
                activeSession = nil
                activeMode = nil
                return
            }

            activeSession = current
            activeMode = mode
            screenTime.apply(mode)
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
        let session = FocusSession(modeID: modeID, trigger: trigger, tagID: tagID)
        // Persist BEFORE applying shields so the state survives a crash.
        try sessionRepository.create(session)
        screenTime.apply(mode)
        activeSession = session
        activeMode = mode
        return mode
    }

    private func stop() throws {
        guard let current = activeSession else { return }
        try endPersisted(current)
        screenTime.clearRestrictions()
        activeSession = nil
        activeMode = nil
    }

    @discardableResult
    private func switchSession(toModeID modeID: UUID, tagID: UUID?) throws -> Mode {
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
}

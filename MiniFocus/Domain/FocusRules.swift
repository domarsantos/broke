//
//  FocusRules.swift
//  MiniFocus
//
//  Pure, hardware-free business rules for what a tag scan should do. Keeping
//  this a plain function makes the core behaviour fully unit-testable.
//

import Foundation

/// Why an action was refused. Surfaced to the user as an informative message;
/// it never ends or changes a session.
enum FocusDenialReason: Equatable {
    /// User tried to stop a locked (Strict/Security) session from the Mini.
    case manualStopBlocked
    /// A registered tag linked to a *different* Mode was scanned while a locked
    /// session is running; we neither end nor switch.
    case lockedDifferentModeTag
}

/// The decision produced by the rules engine for a given scan.
enum FocusAction: Equatable {
    /// Tag is not registered in the app.
    case unregistered
    /// No session running and nothing to activate (registered tag, no linked
    /// Mode and no fallback Mode available).
    case noModeToActivate
    /// Start a session for this Mode.
    case activate(modeID: UUID, tagID: UUID)
    /// Stop the running session.
    case deactivate
    /// Stop the running session and start one for a different Mode.
    case switchTo(modeID: UUID, tagID: UUID)
    /// The scan is refused without changing the running session.
    case denied(FocusDenialReason)
}

enum FocusRules {
    /// Decide what to do when `tag` is scanned.
    ///
    /// - Parameters:
    ///   - tag: the registered tag matching the scanned UID, or `nil` if unknown.
    ///   - activeSession: the session currently running, if any.
    ///   - activeMode: the Mode of the running session, if any. Needed to know
    ///     whether the session is locked (Strict/Security).
    ///   - fallbackModeID: the Mode to use when a registered tag has no linked
    ///     Mode (e.g. the Mode currently selected on the home screen).
    static func action(
        tag: FocusTag?,
        activeSession: FocusSession?,
        activeMode: Mode?,
        fallbackModeID: UUID?
    ) -> FocusAction {
        guard let tag else { return .unregistered }

        let targetModeID = tag.linkedModeID ?? fallbackModeID

        guard let activeSession, activeSession.isActive else {
            // Nothing running: try to activate.
            guard let targetModeID else { return .noModeToActivate }
            return .activate(modeID: targetModeID, tagID: tag.id)
        }

        // A session is running.
        let locked = activeMode?.isNFCLocked ?? false

        // A tag with no specific Mode link is authorized to end any session.
        guard let linkedModeID = tag.linkedModeID else {
            return .deactivate
        }

        if linkedModeID == activeSession.modeID {
            return .deactivate
        }

        // Tag linked to a different Mode.
        // In a locked session we never switch away (that would bypass the lock).
        if locked {
            return .denied(.lockedDifferentModeTag)
        }

        return .switchTo(modeID: linkedModeID, tagID: tag.id)
    }

    // MARK: - Lock policy (centralized, pure)

    /// Whether the active session may be ended by a manual tap in the Mini.
    /// Locked Modes (Strict/Security) require an authorized Mini Tag.
    static func canStopManually(activeMode: Mode) -> Bool {
        !activeMode.isNFCLocked
    }

    /// Whether `tag` is authorized to end a session running `activeMode`.
    /// Authorized = unlinked tag, or a tag linked to the active Mode.
    static func tagIsAuthorized(_ tag: FocusTag, forActiveMode activeMode: Mode) -> Bool {
        tag.linkedModeID == nil || tag.linkedModeID == activeMode.id
    }

    /// Anti-lockout guard: a locked Mode can only be started if at least one
    /// authorized Mini Tag exists for it (linked to the Mode, or unlinked).
    /// Unlocked Modes can always start.
    static func canStartLockedMode(_ mode: Mode, availableTags: [FocusTag]) -> Bool {
        guard mode.isNFCLocked else { return true }
        return availableTags.contains { tag in
            tag.hardwareIdentifier != nil
                && (tag.linkedModeID == nil || tag.linkedModeID == mode.id)
        }
    }
}

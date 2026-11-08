//
//  FocusRules.swift
//  Broke
//
//  Pure, hardware-free business rules for what a tag scan should do. Keeping
//  this a plain function makes the core behaviour fully unit-testable.
//

import Foundation

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
}

enum FocusRules {
    /// Decide what to do when `tag` is scanned.
    ///
    /// - Parameters:
    ///   - tag: the registered tag matching the scanned UID, or `nil` if unknown.
    ///   - activeSession: the session currently running, if any.
    ///   - fallbackModeID: the Mode to use when a registered tag has no linked
    ///     Mode (e.g. the Mode currently selected on the home screen).
    static func action(
        tag: FocusTag?,
        activeSession: FocusSession?,
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
        // A tag with no specific Mode link always toggles off.
        guard let linkedModeID = tag.linkedModeID else {
            return .deactivate
        }

        if linkedModeID == activeSession.modeID {
            return .deactivate
        }

        return .switchTo(modeID: linkedModeID, tagID: tag.id)
    }
}

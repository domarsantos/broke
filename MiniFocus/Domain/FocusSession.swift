//
//  FocusSession.swift
//  MiniFocus
//
//  Domain model for a focus session: the period a Mode stays active.
//

import Foundation

/// What caused a focus session to start.
///
/// Only `.nfc` and `.manual` are supported in V0.2. The enum is intentionally
/// extensible (string-backed) so future triggers (timer, schedule, remote) can
/// be added without breaking stored data.
enum FocusTrigger: String, Codable, Equatable, CaseIterable {
    case nfc
    case manual
    // Reserved for future versions: timer, schedule, remote
}

/// Lifecycle status of a focus session.
enum FocusSessionStatus: String, Codable, Equatable {
    case active
    case completed
}

/// A record of a Mode being active for a period of time.
struct FocusSession: Identifiable, Equatable {
    let id: UUID
    let modeID: UUID
    let startedAt: Date
    var endedAt: Date?
    let trigger: FocusTrigger
    var status: FocusSessionStatus
    /// The tag that started the session, when applicable.
    var tagID: UUID?

    init(
        id: UUID = UUID(),
        modeID: UUID,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        trigger: FocusTrigger,
        status: FocusSessionStatus = .active,
        tagID: UUID? = nil
    ) {
        self.id = id
        self.modeID = modeID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.trigger = trigger
        self.status = status
        self.tagID = tagID
    }

    var isActive: Bool { status == .active && endedAt == nil }

    var duration: TimeInterval {
        (endedAt ?? Date()).timeIntervalSince(startedAt)
    }
}

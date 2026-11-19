//
//  FocusTag.swift
//  MiniFocus
//
//  Domain model for a physical NFC tag paired with the app.
//

import Foundation

/// A physical NFC tag registered by the user.
///
/// `hardwareIdentifier` is the tag UID (hex string) obtained from Core NFC when
/// available. It is used for identification and pairing only, not as a
/// cryptographic secret. A tag may optionally be linked to a `Mode`.
struct FocusTag: Identifiable, Equatable {
    let id: UUID
    var hardwareIdentifier: String?
    var name: String
    var createdAt: Date
    var linkedModeID: UUID?

    init(
        id: UUID = UUID(),
        hardwareIdentifier: String? = nil,
        name: String,
        createdAt: Date = Date(),
        linkedModeID: UUID? = nil
    ) {
        self.id = id
        self.hardwareIdentifier = hardwareIdentifier
        self.name = name
        self.createdAt = createdAt
        self.linkedModeID = linkedModeID
    }
}

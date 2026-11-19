//
//  BrokeSchemaV2.swift
//  MiniFocus
//
//  Schema V2 adds Strict Mode and Modo Segurança to ModeEntity as two Bool
//  flags defaulting to `false`. Tag and Session entities are unchanged in
//  shape but redeclared here so this version owns a complete model graph.
//
//  Migration from V1 is lightweight: the two new attributes have default
//  values, so existing V0.2 stores open without data loss and load with both
//  flags `false`.
//

import Foundation
import SwiftData
import FamilyControls

enum BrokeSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ModeEntity.self, TagEntity.self, SessionEntity.self]
    }

    @Model
    final class ModeEntity {
        @Attribute(.unique) var id: UUID
        var name: String
        var icon: String
        /// JSON-encoded `FamilyActivitySelection`.
        var selectionData: Data
        /// New in V2. Default `false` so migrated V1 Modes stay normal Modes.
        var isStrictMode: Bool = false
        /// New in V2. Default `false`.
        var isSecurityMode: Bool = false
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID,
            name: String,
            icon: String,
            selectionData: Data,
            isStrictMode: Bool = false,
            isSecurityMode: Bool = false,
            createdAt: Date,
            updatedAt: Date
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.selectionData = selectionData
            self.isStrictMode = isStrictMode
            self.isSecurityMode = isSecurityMode
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class TagEntity {
        @Attribute(.unique) var id: UUID
        var hardwareIdentifier: String?
        var name: String
        var createdAt: Date
        var linkedModeID: UUID?

        init(
            id: UUID,
            hardwareIdentifier: String?,
            name: String,
            createdAt: Date,
            linkedModeID: UUID?
        ) {
            self.id = id
            self.hardwareIdentifier = hardwareIdentifier
            self.name = name
            self.createdAt = createdAt
            self.linkedModeID = linkedModeID
        }
    }

    @Model
    final class SessionEntity {
        @Attribute(.unique) var id: UUID
        var modeID: UUID
        var startedAt: Date
        var endedAt: Date?
        var triggerRaw: String
        var statusRaw: String
        var tagID: UUID?

        init(
            id: UUID,
            modeID: UUID,
            startedAt: Date,
            endedAt: Date?,
            triggerRaw: String,
            statusRaw: String,
            tagID: UUID?
        ) {
            self.id = id
            self.modeID = modeID
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.triggerRaw = triggerRaw
            self.statusRaw = statusRaw
            self.tagID = tagID
        }
    }
}

// MARK: - Entity <-> Domain mapping (V2)

extension BrokeSchemaV2.ModeEntity {
    func toDomain() -> Mode {
        let selection = (try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData))
            ?? FamilyActivitySelection()
        return Mode(
            id: id,
            name: name,
            icon: icon,
            selection: selection,
            isStrictMode: isStrictMode,
            isSecurityMode: isSecurityMode,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func selectionData(from selection: FamilyActivitySelection) -> Data {
        (try? JSONEncoder().encode(selection)) ?? Data()
    }

    func apply(_ mode: Mode) {
        name = mode.name
        icon = mode.icon
        selectionData = Self.selectionData(from: mode.selection)
        isStrictMode = mode.isStrictMode
        isSecurityMode = mode.isSecurityMode
        updatedAt = mode.updatedAt
    }
}

extension BrokeSchemaV2.TagEntity {
    func toDomain() -> FocusTag {
        FocusTag(
            id: id,
            hardwareIdentifier: hardwareIdentifier,
            name: name,
            createdAt: createdAt,
            linkedModeID: linkedModeID
        )
    }

    func apply(_ tag: FocusTag) {
        hardwareIdentifier = tag.hardwareIdentifier
        name = tag.name
        linkedModeID = tag.linkedModeID
    }
}

extension BrokeSchemaV2.SessionEntity {
    func toDomain() -> FocusSession {
        FocusSession(
            id: id,
            modeID: modeID,
            startedAt: startedAt,
            endedAt: endedAt,
            trigger: FocusTrigger(rawValue: triggerRaw) ?? .manual,
            status: FocusSessionStatus(rawValue: statusRaw) ?? .completed,
            tagID: tagID
        )
    }

    func apply(_ session: FocusSession) {
        endedAt = session.endedAt
        statusRaw = session.status.rawValue
        tagID = session.tagID
    }
}

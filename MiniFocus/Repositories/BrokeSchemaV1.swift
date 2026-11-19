//
//  BrokeSchemaV1.swift
//  MiniFocus
//
//  SwiftData persistence layer (local-first).
//
//  Why SwiftData: the project targets iOS 17, the models are simple value
//  graphs, and SwiftData gives us a versioned schema + migration plan for free
//  while remaining fully local. The only Apple opaque type we store
//  (FamilyActivitySelection) is kept as Codable `Data`, so no unsafe token
//  serialization happens. Entities reference each other by UUID (not SwiftData
//  relationships) to keep deletes simple and to mirror what a future cloud
//  backend would use.
//

import Foundation
import SwiftData
import FamilyControls

enum BrokeSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

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
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID,
            name: String,
            icon: String,
            selectionData: Data,
            createdAt: Date,
            updatedAt: Date
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.selectionData = selectionData
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

/// Migration plan placeholder. Add stages here when a V2 schema is introduced.
enum BrokeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BrokeSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

// MARK: - Entity <-> Domain mapping

extension BrokeSchemaV1.ModeEntity {
    func toDomain() -> Mode {
        let selection = (try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData))
            ?? FamilyActivitySelection()
        return Mode(
            id: id,
            name: name,
            icon: icon,
            selection: selection,
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
        updatedAt = mode.updatedAt
    }
}

extension BrokeSchemaV1.TagEntity {
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

extension BrokeSchemaV1.SessionEntity {
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

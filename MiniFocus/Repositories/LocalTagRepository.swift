//
//  LocalTagRepository.swift
//  MiniFocus
//
//  SwiftData-backed implementation of TagRepositoryProtocol.
//

import Foundation
import SwiftData

enum TagRepositoryError: Error, Equatable {
    case duplicateHardwareIdentifier
}

@MainActor
final class LocalTagRepository: TagRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [FocusTag] {
        let descriptor = FetchDescriptor<BrokeSchemaV2.TagEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(id: UUID) throws -> FocusTag? {
        try entity(id: id)?.toDomain()
    }

    func fetch(hardwareIdentifier: String) throws -> FocusTag? {
        var descriptor = FetchDescriptor<BrokeSchemaV2.TagEntity>(
            predicate: #Predicate { $0.hardwareIdentifier == hardwareIdentifier }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.toDomain()
    }

    func register(_ tag: FocusTag) throws {
        if let hardwareIdentifier = tag.hardwareIdentifier,
           try fetch(hardwareIdentifier: hardwareIdentifier) != nil {
            throw TagRepositoryError.duplicateHardwareIdentifier
        }
        let entity = BrokeSchemaV2.TagEntity(
            id: tag.id,
            hardwareIdentifier: tag.hardwareIdentifier,
            name: tag.name,
            createdAt: tag.createdAt,
            linkedModeID: tag.linkedModeID
        )
        context.insert(entity)
        try context.save()
    }

    func update(_ tag: FocusTag) throws {
        guard let entity = try entity(id: tag.id) else { return }
        // Guard against colliding with a different tag's identifier.
        if let hardwareIdentifier = tag.hardwareIdentifier,
           let existing = try fetch(hardwareIdentifier: hardwareIdentifier),
           existing.id != tag.id {
            throw TagRepositoryError.duplicateHardwareIdentifier
        }
        entity.apply(tag)
        try context.save()
    }

    func delete(id: UUID) throws {
        guard let entity = try entity(id: id) else { return }
        context.delete(entity)
        try context.save()
    }

    func unlinkMode(_ modeID: UUID) throws {
        let descriptor = FetchDescriptor<BrokeSchemaV2.TagEntity>(
            predicate: #Predicate { $0.linkedModeID == modeID }
        )
        let entities = try context.fetch(descriptor)
        for entity in entities {
            entity.linkedModeID = nil
        }
        if !entities.isEmpty {
            try context.save()
        }
    }

    private func entity(id: UUID) throws -> BrokeSchemaV2.TagEntity? {
        var descriptor = FetchDescriptor<BrokeSchemaV2.TagEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

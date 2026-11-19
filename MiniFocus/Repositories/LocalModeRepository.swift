//
//  LocalModeRepository.swift
//  MiniFocus
//
//  SwiftData-backed implementation of ModeRepositoryProtocol.
//

import Foundation
import SwiftData

@MainActor
final class LocalModeRepository: ModeRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Mode] {
        let descriptor = FetchDescriptor<BrokeSchemaV1.ModeEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(id: UUID) throws -> Mode? {
        try entity(id: id)?.toDomain()
    }

    func create(_ mode: Mode) throws {
        let entity = BrokeSchemaV1.ModeEntity(
            id: mode.id,
            name: mode.name,
            icon: mode.icon,
            selectionData: BrokeSchemaV1.ModeEntity.selectionData(from: mode.selection),
            createdAt: mode.createdAt,
            updatedAt: mode.updatedAt
        )
        context.insert(entity)
        try context.save()
    }

    func update(_ mode: Mode) throws {
        guard let entity = try entity(id: mode.id) else { return }
        entity.apply(mode)
        try context.save()
    }

    func delete(id: UUID) throws {
        guard let entity = try entity(id: id) else { return }
        context.delete(entity)
        try context.save()
    }

    private func entity(id: UUID) throws -> BrokeSchemaV1.ModeEntity? {
        var descriptor = FetchDescriptor<BrokeSchemaV1.ModeEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

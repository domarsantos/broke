//
//  LocalSessionRepository.swift
//  Broke
//
//  SwiftData-backed implementation of SessionRepositoryProtocol.
//

import Foundation
import SwiftData

@MainActor
final class LocalSessionRepository: SessionRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [FocusSession] {
        let descriptor = FetchDescriptor<BrokeSchemaV1.SessionEntity>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(id: UUID) throws -> FocusSession? {
        try entity(id: id)?.toDomain()
    }

    func fetchActive() throws -> [FocusSession] {
        let activeRaw = FocusSessionStatus.active.rawValue
        let descriptor = FetchDescriptor<BrokeSchemaV1.SessionEntity>(
            predicate: #Predicate { $0.statusRaw == activeRaw },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func create(_ session: FocusSession) throws {
        let entity = BrokeSchemaV1.SessionEntity(
            id: session.id,
            modeID: session.modeID,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            triggerRaw: session.trigger.rawValue,
            statusRaw: session.status.rawValue,
            tagID: session.tagID
        )
        context.insert(entity)
        try context.save()
    }

    func update(_ session: FocusSession) throws {
        guard let entity = try entity(id: session.id) else { return }
        entity.apply(session)
        try context.save()
    }

    func delete(id: UUID) throws {
        guard let entity = try entity(id: id) else { return }
        context.delete(entity)
        try context.save()
    }

    private func entity(id: UUID) throws -> BrokeSchemaV1.SessionEntity? {
        var descriptor = FetchDescriptor<BrokeSchemaV1.SessionEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

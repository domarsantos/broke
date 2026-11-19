//
//  TagStore.swift
//  MiniFocus
//
//  Observable source of truth for the registered NFC tags.
//

import Foundation
import Observation

@MainActor
@Observable
final class TagStore {
    private(set) var tags: [FocusTag] = []

    @ObservationIgnored private let repository: TagRepositoryProtocol

    init(repository: TagRepositoryProtocol) {
        self.repository = repository
    }

    func load() {
        tags = (try? repository.fetchAll()) ?? []
    }

    @discardableResult
    func register(hardwareIdentifier: String?, name: String, linkedModeID: UUID?) throws -> FocusTag {
        let tag = FocusTag(hardwareIdentifier: hardwareIdentifier, name: name, linkedModeID: linkedModeID)
        try repository.register(tag)
        load()
        return tag
    }

    func rename(_ tag: FocusTag, to name: String) {
        var updated = tag
        updated.name = name
        try? repository.update(updated)
        load()
    }

    func setLinkedMode(_ tag: FocusTag, modeID: UUID?) {
        var updated = tag
        updated.linkedModeID = modeID
        try? repository.update(updated)
        load()
    }

    func delete(id: UUID) {
        try? repository.delete(id: id)
        load()
    }

    func tag(forHardwareIdentifier identifier: String) -> FocusTag? {
        try? repository.fetch(hardwareIdentifier: identifier)
    }
}

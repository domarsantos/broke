//
//  ModeStore.swift
//  MiniFocus
//
//  Observable source of truth for the list of Modes and the currently
//  selected Mode (the one activated when scanning an unlinked tag or starting
//  manually). Persists the selection via UserDefaults; the Modes themselves
//  live in the repository.
//

import Foundation
import FamilyControls
import Observation

@MainActor
@Observable
final class ModeStore {
    private(set) var modes: [Mode] = []
    var selectedModeID: UUID? {
        didSet { persistSelection() }
    }

    @ObservationIgnored private let repository: ModeRepositoryProtocol
    @ObservationIgnored private let defaults: UserDefaults

    init(repository: ModeRepositoryProtocol, defaults: UserDefaults = .standard) {
        self.repository = repository
        self.defaults = defaults
        if let raw = defaults.string(forKey: BrokeDefaultsKey.selectedModeID) {
            _selectedModeID = UUID(uuidString: raw)
        }
    }

    var selectedMode: Mode? {
        modes.first { $0.id == selectedModeID } ?? modes.first
    }

    func load() {
        modes = (try? repository.fetchAll()) ?? []
        if selectedModeID == nil || !modes.contains(where: { $0.id == selectedModeID }) {
            selectedModeID = modes.first?.id
        }
    }

    /// Ensures at least one Mode exists (defensive; the migrator normally seeds).
    func ensureDefault() {
        guard modes.isEmpty else { return }
        let fallback = Mode(name: "Meu foco", icon: "bell.slash")
        try? repository.create(fallback)
        load()
    }

    func select(_ id: UUID) {
        guard modes.contains(where: { $0.id == id }) else { return }
        selectedModeID = id
    }

    @discardableResult
    func add(name: String, icon: String, selection: FamilyActivitySelection) -> Mode {
        let mode = Mode(name: name, icon: icon, selection: selection)
        try? repository.create(mode)
        load()
        selectedModeID = mode.id
        return mode
    }

    func update(id: UUID, name: String, icon: String, selection: FamilyActivitySelection) {
        guard var mode = modes.first(where: { $0.id == id }) else { return }
        mode.name = name
        mode.icon = icon
        mode.selection = selection
        mode.updatedAt = Date()
        try? repository.update(mode)
        load()
    }

    /// Low-level delete. Prefer `AppEnvironment.deleteMode` which also unlinks tags
    /// and refuses to delete the active Mode.
    func delete(id: UUID) {
        try? repository.delete(id: id)
        load()
    }

    func mode(id: UUID?) -> Mode? {
        guard let id else { return nil }
        return modes.first { $0.id == id }
    }

    private func persistSelection() {
        defaults.set(selectedModeID?.uuidString, forKey: BrokeDefaultsKey.selectedModeID)
    }
}

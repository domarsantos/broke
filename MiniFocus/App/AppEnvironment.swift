//
//  AppEnvironment.swift
//  MiniFocus
//
//  Composition root. Wires the SwiftData container, repositories, services and
//  stores together and runs one-time migration + session recovery. Injected
//  into the SwiftUI environment so Views depend only on high-level objects.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class AppEnvironment {
    let modeStore: ModeStore
    let tagStore: TagStore
    let focusController: FocusController
    let nfcService: NFCServiceProtocol
    let screenTime: ScreenTimeServiceProtocol

    @ObservationIgnored private let modeRepository: ModeRepositoryProtocol
    @ObservationIgnored private let tagRepository: TagRepositoryProtocol

    init() {
        let container = PersistenceController.makeSharedContainer()
        let context = ModelContext(container)

        let modeRepository = LocalModeRepository(context: context)
        let tagRepository = LocalTagRepository(context: context)
        let sessionRepository = LocalSessionRepository(context: context)
        let screenTime = ScreenTimeService()

        self.modeRepository = modeRepository
        self.tagRepository = tagRepository
        self.screenTime = screenTime
        self.nfcService = NFCService()

        // One-time migration from v0.1 before loading the stores.
        _ = try? LegacyDataMigrator(
            modeRepository: modeRepository,
            sessionRepository: sessionRepository
        ).migrateIfNeeded()

        self.modeStore = ModeStore(repository: modeRepository)
        self.tagStore = TagStore(repository: tagRepository)
        self.focusController = FocusController(
            modeRepository: modeRepository,
            tagRepository: tagRepository,
            sessionRepository: sessionRepository,
            screenTime: screenTime
        )

        modeStore.load()
        modeStore.ensureDefault()
        tagStore.load()
        focusController.recover()
    }

    /// Requests Screen Time authorization on launch (skipped during tests).
    func bootstrap() async {
        guard !AppEnvironment.isRunningTests else { return }
        if !screenTime.isAuthorized {
            try? await screenTime.authorize()
        }
    }

    /// Delete a Mode safely: the active Mode cannot be deleted, and any tags
    /// linked to it are unlinked first.
    @discardableResult
    func deleteMode(_ id: UUID) -> Bool {
        guard focusController.activeMode?.id != id else { return false }
        try? tagRepository.unlinkMode(id)
        modeStore.delete(id: id)
        tagStore.load()
        return true
    }

    /// Reapply restrictions if the edited Mode is the one currently active.
    /// Editing a locked active Mode is blocked at the UI level, so this only
    /// runs for normal (unlocked) active Modes.
    func modeWasEdited(_ id: UUID) {
        guard focusController.activeMode?.id == id,
              let updated = modeStore.mode(id: id) else { return }
        try? screenTime.reconcile(activeMode: updated)
    }

    /// Whether the given Mode is the currently active, locked session. Views use
    /// this to freeze editing and tag management while locked.
    func isModeLockedActive(_ id: UUID) -> Bool {
        focusController.isLockedActive && focusController.activeMode?.id == id
    }

    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}

//
//  LegacyDataMigrator.swift
//  MiniFocus
//
//  One-time, idempotent migration from the v0.1 UserDefaults format
//  (Profiles) to the v0.2 SwiftData format (Modes + Sessions).
//
//  The old UserDefaults keys are intentionally NOT deleted so the user can roll
//  back to v0.1 if needed. A flag prevents the migration from running twice.
//

import Foundation
import FamilyControls
import ManagedSettings

enum BrokeDefaultsKey {
    static let savedProfiles = "savedProfiles"
    static let currentProfileId = "currentProfileId"
    static let isBlocking = "isBlocking"
    static let didMigrateToV02 = "didMigrateToV02"
    static let selectedModeID = "selectedModeID"
}

/// Mirrors the exact Codable shape of the v0.1 `Profile` struct so stored data
/// decodes cleanly even after the legacy types are removed.
private struct LegacyProfile: Codable {
    let id: UUID
    var name: String
    var appTokens: Set<ApplicationToken>
    var categoryTokens: Set<ActivityCategoryToken>
    var icon: String
}

struct MigrationResult: Equatable {
    var createdModeIDs: [UUID]
    var selectedModeID: UUID?
    var createdActiveSession: Bool
}

@MainActor
struct LegacyDataMigrator {
    let modeRepository: ModeRepositoryProtocol
    let sessionRepository: SessionRepositoryProtocol
    let defaults: UserDefaults

    init(
        modeRepository: ModeRepositoryProtocol,
        sessionRepository: SessionRepositoryProtocol,
        defaults: UserDefaults = .standard
    ) {
        self.modeRepository = modeRepository
        self.sessionRepository = sessionRepository
        self.defaults = defaults
    }

    /// Runs the migration once. Returns the result, or `nil` if it had already
    /// run previously.
    @discardableResult
    func migrateIfNeeded() throws -> MigrationResult? {
        guard !defaults.bool(forKey: BrokeDefaultsKey.didMigrateToV02) else {
            return nil
        }

        var result = MigrationResult(createdModeIDs: [], selectedModeID: nil, createdActiveSession: false)

        let legacyProfiles = decodeLegacyProfiles()

        if legacyProfiles.isEmpty {
            // Fresh install (or nothing to migrate): seed a default mode.
            let defaultMode = Mode(name: "Meu foco", icon: "bell.slash")
            try modeRepository.create(defaultMode)
            result.createdModeIDs = [defaultMode.id]
            result.selectedModeID = defaultMode.id
        } else {
            for profile in legacyProfiles {
                var selection = FamilyActivitySelection()
                selection.applicationTokens = profile.appTokens
                selection.categoryTokens = profile.categoryTokens
                let mode = Mode(
                    id: profile.id, // preserve id so tags/sessions stay valid
                    name: profile.name,
                    icon: profile.icon,
                    selection: selection
                )
                try modeRepository.create(mode)
                result.createdModeIDs.append(mode.id)
            }

            result.selectedModeID = resolveSelectedModeID(from: legacyProfiles)

            // If v0.1 was actively blocking, the shields are already applied on
            // the device. Create a matching active session so we don't silently
            // unblock on first launch.
            if defaults.bool(forKey: BrokeDefaultsKey.isBlocking),
               let selectedModeID = result.selectedModeID {
                let session = FocusSession(modeID: selectedModeID, trigger: .nfc, status: .active)
                try sessionRepository.create(session)
                result.createdActiveSession = true
            }
        }

        if let selectedModeID = result.selectedModeID {
            defaults.set(selectedModeID.uuidString, forKey: BrokeDefaultsKey.selectedModeID)
        }
        defaults.set(true, forKey: BrokeDefaultsKey.didMigrateToV02)
        return result
    }

    private func decodeLegacyProfiles() -> [LegacyProfile] {
        guard let data = defaults.data(forKey: BrokeDefaultsKey.savedProfiles),
              let profiles = try? JSONDecoder().decode([LegacyProfile].self, from: data) else {
            return []
        }
        return profiles
    }

    private func resolveSelectedModeID(from profiles: [LegacyProfile]) -> UUID? {
        if let raw = defaults.string(forKey: BrokeDefaultsKey.currentProfileId),
           let uuid = UUID(uuidString: raw),
           profiles.contains(where: { $0.id == uuid }) {
            return uuid
        }
        if let defaultProfile = profiles.first(where: { $0.name == "Default" }) {
            return defaultProfile.id
        }
        return profiles.first?.id
    }
}

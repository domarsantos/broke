//
//  LegacyDataMigratorTests.swift
//  BrokeTests
//

import XCTest
import SwiftData
@testable import Broke

@MainActor
final class LegacyDataMigratorTests: XCTestCase {
    private var context: ModelContext!
    private var modeRepo: LocalModeRepository!
    private var sessionRepo: LocalSessionRepository!
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        context = TestSupport.inMemoryContext()
        modeRepo = LocalModeRepository(context: context)
        sessionRepo = LocalSessionRepository(context: context)
        suiteName = "migrator-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeMigrator() -> LegacyDataMigrator {
        LegacyDataMigrator(modeRepository: modeRepo, sessionRepository: sessionRepo, defaults: defaults)
    }

    /// Encodes legacy profiles using the same shape the v0.1 app used.
    private func seedLegacyProfiles(_ profiles: [[String: Any]], currentId: UUID?, isBlocking: Bool) throws {
        // Build JSON with empty token sets (tokens are opaque and device-bound).
        var array: [[String: Any]] = []
        for p in profiles {
            array.append([
                "id": (p["id"] as! UUID).uuidString,
                "name": p["name"] as! String,
                "appTokens": [],
                "categoryTokens": [],
                "icon": p["icon"] as! String
            ])
        }
        let data = try JSONSerialization.data(withJSONObject: array)
        defaults.set(data, forKey: BrokeDefaultsKey.savedProfiles)
        if let currentId { defaults.set(currentId.uuidString, forKey: BrokeDefaultsKey.currentProfileId) }
        defaults.set(isBlocking, forKey: BrokeDefaultsKey.isBlocking)
    }

    func testFreshInstallSeedsDefaultMode() throws {
        let result = try makeMigrator().migrateIfNeeded()
        XCTAssertNotNil(result)
        let modes = try modeRepo.fetchAll()
        XCTAssertEqual(modes.count, 1)
        XCTAssertEqual(modes.first?.name, "Default")
        XCTAssertEqual(result?.selectedModeID, modes.first?.id)
    }

    func testMigratesLegacyProfilesPreservingIDs() throws {
        let workID = UUID()
        let studyID = UUID()
        try seedLegacyProfiles(
            [["id": workID, "name": "Work", "icon": "briefcase"],
             ["id": studyID, "name": "Study", "icon": "book"]],
            currentId: studyID,
            isBlocking: false
        )

        let result = try makeMigrator().migrateIfNeeded()

        let modes = try modeRepo.fetchAll()
        XCTAssertEqual(Set(modes.map(\.id)), [workID, studyID])
        XCTAssertEqual(result?.selectedModeID, studyID)
        XCTAssertEqual(result?.createdActiveSession, false)
        XCTAssertEqual(defaults.string(forKey: BrokeDefaultsKey.selectedModeID), studyID.uuidString)
    }

    func testBlockingStateCreatesActiveSession() throws {
        let workID = UUID()
        try seedLegacyProfiles(
            [["id": workID, "name": "Work", "icon": "briefcase"]],
            currentId: workID,
            isBlocking: true
        )

        let result = try makeMigrator().migrateIfNeeded()

        XCTAssertEqual(result?.createdActiveSession, true)
        let active = try sessionRepo.fetchActive()
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.modeID, workID)
    }

    func testMigrationIsIdempotent() throws {
        try seedLegacyProfiles(
            [["id": UUID(), "name": "Work", "icon": "briefcase"]],
            currentId: nil,
            isBlocking: false
        )
        _ = try makeMigrator().migrateIfNeeded()
        let secondRun = try makeMigrator().migrateIfNeeded()

        XCTAssertNil(secondRun)
        XCTAssertEqual(try modeRepo.fetchAll().count, 1)
    }

    func testLegacyKeysArePreserved() throws {
        try seedLegacyProfiles(
            [["id": UUID(), "name": "Work", "icon": "briefcase"]],
            currentId: nil,
            isBlocking: false
        )
        _ = try makeMigrator().migrateIfNeeded()
        XCTAssertNotNil(defaults.data(forKey: BrokeDefaultsKey.savedProfiles))
    }
}

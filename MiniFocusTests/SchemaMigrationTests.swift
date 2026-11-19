//
//  SchemaMigrationTests.swift
//  MiniFocusTests
//
//  Verifies the lightweight V1 -> V2 migration: a store written with the V0.2
//  schema (no Strict/Security flags) opens under V2 without data loss, and the
//  migrated Modes load with both flags `false`.
//

import XCTest
import SwiftData
@testable import MiniFocus

@MainActor
final class SchemaMigrationTests: XCTestCase {
    private var storeURL: URL!

    override func setUp() {
        super.setUp()
        storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("migration-\(UUID().uuidString).store")
    }

    override func tearDown() {
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension(suffix))
            try? FileManager.default.removeItem(
                at: storeURL.deletingPathExtension().appendingPathExtension("store\(suffix)")
            )
        }
        try? FileManager.default.removeItem(at: storeURL)
        super.tearDown()
    }

    /// Writes one Mode/Tag/Session using the V1 schema, then lets the container
    /// deallocate so the file is released before we reopen it.
    private func seedV1Store(modeID: UUID) throws {
        let schema = Schema(versionedSchema: BrokeSchemaV1.self)
        let config = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let now = Date()
        context.insert(BrokeSchemaV1.ModeEntity(
            id: modeID,
            name: "Legacy Work",
            icon: "briefcase",
            selectionData: Data(),
            createdAt: now,
            updatedAt: now
        ))
        try context.save()
    }

    func testV1StoreMigratesToV2WithFlagsFalse() throws {
        let modeID = UUID()
        try seedV1Store(modeID: modeID)

        // Reopen the same file using the V2 schema + migration plan.
        let container = PersistenceController.makeContainer(at: storeURL)
        let repo = LocalModeRepository(context: ModelContext(container))

        let modes = try repo.fetchAll()
        XCTAssertEqual(modes.count, 1)
        let migrated = try XCTUnwrap(modes.first)
        XCTAssertEqual(migrated.id, modeID)
        XCTAssertEqual(migrated.name, "Legacy Work")
        XCTAssertFalse(migrated.isStrictMode, "Migrated V1 Mode must default to non-strict")
        XCTAssertFalse(migrated.isSecurityMode, "Migrated V1 Mode must default to non-security")
    }
}

//
//  LocalSessionRepositoryTests.swift
//  MiniFocusTests
//

import XCTest
import SwiftData
@testable import MiniFocus

@MainActor
final class LocalSessionRepositoryTests: XCTestCase {
    func testCreateStartAndFetchActive() throws {
        let repository = LocalSessionRepository(context: TestSupport.inMemoryContext())
        let session = FocusSession(modeID: UUID(), trigger: .nfc)
        try repository.create(session)

        let active = try repository.fetchActive()
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.id, session.id)
        XCTAssertTrue(active.first?.isActive == true)
    }

    func testStopSessionClearsActive() throws {
        let repository = LocalSessionRepository(context: TestSupport.inMemoryContext())
        var session = FocusSession(modeID: UUID(), trigger: .manual)
        try repository.create(session)

        session.endedAt = Date()
        session.status = .completed
        try repository.update(session)

        XCTAssertTrue(try repository.fetchActive().isEmpty)
        XCTAssertEqual(try repository.fetch(id: session.id)?.status, .completed)
    }

    func testActiveSessionSurvivesRelaunch() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("broke-session-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        let session = FocusSession(modeID: UUID(), trigger: .nfc)

        // First "launch": create an active session, then drop the container.
        do {
            let container = PersistenceController.makeContainer(at: url)
            let repository = LocalSessionRepository(context: ModelContext(container))
            try repository.create(session)
        }

        // Second "launch": a fresh container from the same file must recover it.
        let container = PersistenceController.makeContainer(at: url)
        let repository = LocalSessionRepository(context: ModelContext(container))
        let active = try repository.fetchActive()
        XCTAssertEqual(active.first?.id, session.id)
    }
}

//
//  LocalModeRepositoryTests.swift
//  MiniFocusTests
//

import XCTest
import SwiftData
@testable import MiniFocus

@MainActor
final class LocalModeRepositoryTests: XCTestCase {
    private var repository: LocalModeRepository!

    override func setUp() {
        super.setUp()
        repository = LocalModeRepository(context: TestSupport.inMemoryContext())
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testCreateAndFetch() throws {
        let mode = TestSupport.makeMode(name: "Study")
        try repository.create(mode)

        let fetched = try repository.fetch(id: mode.id)
        XCTAssertEqual(fetched?.id, mode.id)
        XCTAssertEqual(fetched?.name, "Study")
        XCTAssertEqual(try repository.fetchAll().count, 1)
    }

    func testUpdate() throws {
        var mode = TestSupport.makeMode(name: "Work")
        try repository.create(mode)

        mode.name = "Deep Work"
        mode.icon = "moon"
        mode.updatedAt = Date()
        try repository.update(mode)

        let fetched = try repository.fetch(id: mode.id)
        XCTAssertEqual(fetched?.name, "Deep Work")
        XCTAssertEqual(fetched?.icon, "moon")
    }

    func testDelete() throws {
        let mode = TestSupport.makeMode()
        try repository.create(mode)
        try repository.delete(id: mode.id)

        XCTAssertNil(try repository.fetch(id: mode.id))
        XCTAssertTrue(try repository.fetchAll().isEmpty)
    }

    func testFetchAllIsSortedByCreation() throws {
        let first = Mode(name: "A", createdAt: Date(timeIntervalSince1970: 1))
        let second = Mode(name: "B", createdAt: Date(timeIntervalSince1970: 2))
        try repository.create(second)
        try repository.create(first)

        let all = try repository.fetchAll()
        XCTAssertEqual(all.map(\.name), ["A", "B"])
    }

    func testNewModeDefaultsToUnlocked() throws {
        let mode = TestSupport.makeMode(name: "Default")
        try repository.create(mode)
        let fetched = try repository.fetch(id: mode.id)
        XCTAssertEqual(fetched?.isStrictMode, false)
        XCTAssertEqual(fetched?.isSecurityMode, false)
    }

    func testStrictAndSecurityFlagsRoundTrip() throws {
        let mode = Mode(name: "Bank", isStrictMode: true, isSecurityMode: true)
        try repository.create(mode)
        var fetched = try XCTUnwrap(try repository.fetch(id: mode.id))
        XCTAssertTrue(fetched.isStrictMode)
        XCTAssertTrue(fetched.isSecurityMode)

        fetched.isStrictMode = false
        try repository.update(fetched)
        let updated = try repository.fetch(id: mode.id)
        XCTAssertEqual(updated?.isStrictMode, false)
        XCTAssertEqual(updated?.isSecurityMode, true)
    }
}

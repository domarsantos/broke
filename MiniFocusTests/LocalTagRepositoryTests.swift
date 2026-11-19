//
//  LocalTagRepositoryTests.swift
//  MiniFocusTests
//

import XCTest
import SwiftData
@testable import MiniFocus

@MainActor
final class LocalTagRepositoryTests: XCTestCase {
    private var repository: LocalTagRepository!

    override func setUp() {
        super.setUp()
        repository = LocalTagRepository(context: TestSupport.inMemoryContext())
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testRegisterAndLookupByIdentifier() throws {
        let tag = TestSupport.makeTag(hardwareIdentifier: "04DEADBEEF", name: "Home")
        try repository.register(tag)

        let found = try repository.fetch(hardwareIdentifier: "04DEADBEEF")
        XCTAssertEqual(found?.id, tag.id)
        XCTAssertEqual(found?.name, "Home")
    }

    func testLookupUnknownIdentifierReturnsNil() throws {
        XCTAssertNil(try repository.fetch(hardwareIdentifier: "DOES-NOT-EXIST"))
    }

    func testRegisterDuplicateIdentifierThrows() throws {
        try repository.register(TestSupport.makeTag(hardwareIdentifier: "AABB", name: "One"))
        XCTAssertThrowsError(
            try repository.register(TestSupport.makeTag(hardwareIdentifier: "AABB", name: "Two"))
        ) { error in
            XCTAssertEqual(error as? TagRepositoryError, .duplicateHardwareIdentifier)
        }
    }

    func testLinkAndUnlinkMode() throws {
        let modeID = UUID()
        var tag = TestSupport.makeTag(hardwareIdentifier: "CC01", name: "Desk")
        try repository.register(tag)

        tag.linkedModeID = modeID
        try repository.update(tag)
        XCTAssertEqual(try repository.fetch(id: tag.id)?.linkedModeID, modeID)

        try repository.unlinkMode(modeID)
        XCTAssertNil(try repository.fetch(id: tag.id)?.linkedModeID)
    }

    func testDelete() throws {
        let tag = TestSupport.makeTag(hardwareIdentifier: "DD02")
        try repository.register(tag)
        try repository.delete(id: tag.id)
        XCTAssertTrue(try repository.fetchAll().isEmpty)
    }
}

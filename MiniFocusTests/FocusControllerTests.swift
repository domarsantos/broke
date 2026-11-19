//
//  FocusControllerTests.swift
//  MiniFocusTests
//

import XCTest
import SwiftData
@testable import MiniFocus

@MainActor
final class FocusControllerTests: XCTestCase {
    private var context: ModelContext!
    private var modeRepo: LocalModeRepository!
    private var tagRepo: LocalTagRepository!
    private var sessionRepo: LocalSessionRepository!
    private var screenTime: FakeScreenTimeService!
    private var controller: FocusController!

    override func setUp() {
        super.setUp()
        context = TestSupport.inMemoryContext()
        modeRepo = LocalModeRepository(context: context)
        tagRepo = LocalTagRepository(context: context)
        sessionRepo = LocalSessionRepository(context: context)
        screenTime = FakeScreenTimeService()
        controller = FocusController(
            modeRepository: modeRepo,
            tagRepository: tagRepo,
            sessionRepository: sessionRepo,
            screenTime: screenTime
        )
    }

    private func seedModeAndTag(uid: String) throws -> (mode: Mode, tag: FocusTag) {
        let mode = TestSupport.makeMode(name: "Work")
        try modeRepo.create(mode)
        let tag = FocusTag(hardwareIdentifier: uid, name: "Office", linkedModeID: mode.id)
        try tagRepo.register(tag)
        return (mode, tag)
    }

    // No session + Tag A -> starts Mode A
    func testScanStartsSession() throws {
        let (mode, _) = try seedModeAndTag(uid: "AAA")
        let outcome = try controller.handleScan(ScannedTag(hardwareIdentifier: "AAA", ndefText: nil), fallbackModeID: nil)

        XCTAssertEqual(outcome, .activated(mode))
        XCTAssertTrue(controller.isActive)
        XCTAssertEqual(controller.activeMode?.id, mode.id)
        XCTAssertEqual(screenTime.lastAppliedMode?.id, mode.id)
        XCTAssertEqual(try sessionRepo.fetchActive().count, 1)
    }

    // Mode A active + Tag A -> stops Mode A
    func testRescanSameTagStops() throws {
        let (_, _) = try seedModeAndTag(uid: "AAA")
        let scan = ScannedTag(hardwareIdentifier: "AAA", ndefText: nil)
        try controller.handleScan(scan, fallbackModeID: nil)
        let outcome = try controller.handleScan(scan, fallbackModeID: nil)

        XCTAssertEqual(outcome, .deactivated)
        XCTAssertFalse(controller.isActive)
        XCTAssertTrue(try sessionRepo.fetchActive().isEmpty)
        XCTAssertEqual(screenTime.clearCount, 1)
        // One completed session remains in history.
        XCTAssertEqual(try sessionRepo.fetchAll().count, 1)
    }

    // Mode A active + Tag B -> switches to Mode B
    func testScanDifferentTagSwitches() throws {
        let (_, _) = try seedModeAndTag(uid: "AAA")
        let modeB = TestSupport.makeMode(name: "Study")
        try modeRepo.create(modeB)
        try tagRepo.register(FocusTag(hardwareIdentifier: "BBB", name: "Desk", linkedModeID: modeB.id))

        try controller.handleScan(ScannedTag(hardwareIdentifier: "AAA", ndefText: nil), fallbackModeID: nil)
        let outcome = try controller.handleScan(ScannedTag(hardwareIdentifier: "BBB", ndefText: nil), fallbackModeID: nil)

        XCTAssertEqual(outcome, .switched(modeB))
        XCTAssertEqual(controller.activeMode?.id, modeB.id)
        XCTAssertEqual(try sessionRepo.fetchActive().count, 1)
        XCTAssertEqual(try sessionRepo.fetchActive().first?.modeID, modeB.id)
        // Two sessions total: one completed (A), one active (B).
        XCTAssertEqual(try sessionRepo.fetchAll().count, 2)
    }

    func testUnregisteredTagReturnsUnregistered() throws {
        let scan = ScannedTag(hardwareIdentifier: "ZZZ", ndefText: "BROKE-IS-GREAT")
        let outcome = try controller.handleScan(scan, fallbackModeID: nil)
        XCTAssertEqual(outcome, .unregistered(scan))
        XCTAssertFalse(controller.isActive)
    }

    func testManualStartThenStopByTag() throws {
        let mode = TestSupport.makeMode(name: "Reading")
        try modeRepo.create(mode)
        // Tag linked to the same mode so a rescan stops it.
        try tagRepo.register(FocusTag(hardwareIdentifier: "CCC", name: "Book", linkedModeID: mode.id))

        try controller.startManual(modeID: mode.id)
        XCTAssertTrue(controller.isActive)
        XCTAssertEqual(try sessionRepo.fetchActive().first?.trigger, .manual)

        let outcome = try controller.handleScan(ScannedTag(hardwareIdentifier: "CCC", ndefText: nil), fallbackModeID: nil)
        XCTAssertEqual(outcome, .deactivated)
        XCTAssertFalse(controller.isActive)
    }

    func testRecoverReappliesActiveSession() throws {
        let (mode, _) = try seedModeAndTag(uid: "AAA")
        try controller.handleScan(ScannedTag(hardwareIdentifier: "AAA", ndefText: nil), fallbackModeID: nil)

        // Simulate relaunch: fresh controller over the same store.
        let fresh = FocusController(
            modeRepository: modeRepo,
            tagRepository: tagRepo,
            sessionRepository: sessionRepo,
            screenTime: screenTime
        )
        fresh.recover()

        XCTAssertTrue(fresh.isActive)
        XCTAssertEqual(fresh.activeMode?.id, mode.id)
        XCTAssertEqual(screenTime.lastAppliedMode?.id, mode.id)
    }

    func testRecoverClearsWhenModeDeleted() throws {
        let (mode, _) = try seedModeAndTag(uid: "AAA")
        try controller.handleScan(ScannedTag(hardwareIdentifier: "AAA", ndefText: nil), fallbackModeID: nil)
        try modeRepo.delete(id: mode.id)

        let fresh = FocusController(
            modeRepository: modeRepo,
            tagRepository: tagRepo,
            sessionRepository: sessionRepo,
            screenTime: screenTime
        )
        fresh.recover()

        XCTAssertFalse(fresh.isActive)
        XCTAssertTrue(try sessionRepo.fetchActive().isEmpty)
    }
}

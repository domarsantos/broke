//
//  FocusControllerTests.swift
//  MiniFocusTests
//

import XCTest
import SwiftData
import FamilyControls
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

    // MARK: - Strict Mode

    private func seedLockedMode(strict: Bool, security: Bool, uid: String?) throws -> (Mode, FocusTag?) {
        var selection = FamilyActivitySelection()
        if security {
            // Security requires apps; we cannot forge real tokens in a unit
            // test, so security controller tests that need activation use the
            // Fake which skips the empty check only when apps exist. For rule
            // tests we keep selection empty and assert the guard instead.
        }
        let mode = Mode(name: "Deep", selection: selection, isStrictMode: strict, isSecurityMode: security)
        try modeRepo.create(mode)
        var tag: FocusTag?
        if let uid {
            let t = FocusTag(hardwareIdentifier: uid, name: "Key", linkedModeID: mode.id)
            try tagRepo.register(t)
            tag = t
        }
        return (mode, tag)
    }

    // Normal manual stop is allowed.
    func testNormalManualStopAllowed() throws {
        let mode = TestSupport.makeMode(name: "Normal")
        try modeRepo.create(mode)
        try controller.startManual(modeID: mode.id)
        XCTAssertTrue(controller.isActive)

        try controller.stopManual()
        XCTAssertFalse(controller.isActive)
        XCTAssertEqual(screenTime.clearCount, 1)
    }

    // Strict manual stop is denied and keeps the session active.
    func testStrictManualStopDenied() throws {
        let (mode, _) = try seedLockedMode(strict: true, security: false, uid: "KEY")
        try controller.startManual(modeID: mode.id)
        XCTAssertTrue(controller.isActive)

        XCTAssertThrowsError(try controller.stopManual()) { error in
            XCTAssertEqual(error as? FocusControllerError, .manualStopBlocked)
        }
        XCTAssertTrue(controller.isActive, "Session must remain active after a blocked manual stop")
    }

    // Strict + authorized NFC tag stops the session.
    func testStrictAuthorizedTagStops() throws {
        let (_, _) = try seedLockedMode(strict: true, security: false, uid: "KEY")
        _ = try controller.startManual(modeID: modeRepo.fetchAll().first!.id)
        XCTAssertTrue(controller.isActive)

        let outcome = try controller.handleScan(ScannedTag(hardwareIdentifier: "KEY", ndefText: nil), fallbackModeID: nil)
        XCTAssertEqual(outcome, .deactivated)
        XCTAssertFalse(controller.isActive)
    }

    // Strict + unknown NFC tag does not stop.
    func testStrictUnknownTagDoesNotStop() throws {
        let (mode, _) = try seedLockedMode(strict: true, security: false, uid: "KEY")
        try controller.startManual(modeID: mode.id)

        let outcome = try controller.handleScan(ScannedTag(hardwareIdentifier: "ZZZ", ndefText: nil), fallbackModeID: nil)
        XCTAssertEqual(outcome, .unregistered(ScannedTag(hardwareIdentifier: "ZZZ", ndefText: nil)))
        XCTAssertTrue(controller.isActive)
    }

    // Strict + a tag linked to another mode is denied (no switch, no stop).
    func testStrictOtherModeTagDenied() throws {
        let (mode, _) = try seedLockedMode(strict: true, security: false, uid: "KEY")
        let other = TestSupport.makeMode(name: "Other")
        try modeRepo.create(other)
        try tagRepo.register(FocusTag(hardwareIdentifier: "OTH", name: "Other", linkedModeID: other.id))
        try controller.startManual(modeID: mode.id)

        let outcome = try controller.handleScan(ScannedTag(hardwareIdentifier: "OTH", ndefText: nil), fallbackModeID: nil)
        XCTAssertEqual(outcome, .denied(.lockedDifferentModeTag))
        XCTAssertTrue(controller.isActive)
        XCTAssertEqual(controller.activeMode?.id, mode.id)
    }

    // MARK: - Anti-lockout guard

    func testLockedModeWithoutAuthorizedTagCannotStart() throws {
        let (mode, _) = try seedLockedMode(strict: true, security: false, uid: nil)
        XCTAssertThrowsError(try controller.startManual(modeID: mode.id)) { error in
            XCTAssertEqual(error as? FocusControllerError, .lockedModeNeedsAuthorizedTag)
        }
        XCTAssertFalse(controller.isActive)
        XCTAssertTrue(try sessionRepo.fetchActive().isEmpty)
    }

    // MARK: - Authorization / activation failures

    func testStartFailsWhenNotAuthorized() throws {
        screenTime.isAuthorized = false
        let (mode, _) = try seedLockedMode(strict: true, security: false, uid: "KEY")
        XCTAssertThrowsError(try controller.startManual(modeID: mode.id)) { error in
            XCTAssertEqual(error as? FocusControllerError, .notAuthorized)
        }
        XCTAssertTrue(try sessionRepo.fetchActive().isEmpty, "No session may persist without authorization")
    }

    func testActivationFailureRollsBackSession() throws {
        let mode = TestSupport.makeMode(name: "Normal")
        try modeRepo.create(mode)
        screenTime.activateError = ScreenTimeError.applyVerificationFailed

        XCTAssertThrowsError(try controller.startManual(modeID: mode.id)) { error in
            XCTAssertEqual(error as? FocusControllerError, .activationFailed)
        }
        XCTAssertFalse(controller.isActive)
        XCTAssertTrue(try sessionRepo.fetchActive().isEmpty, "Session must be rolled back on activation failure")
    }

    func testDeactivationFailureKeepsSessionActive() throws {
        let mode = TestSupport.makeMode(name: "Normal")
        try modeRepo.create(mode)
        try controller.startManual(modeID: mode.id)
        screenTime.deactivateError = ScreenTimeError.clearVerificationFailed

        XCTAssertThrowsError(try controller.stopManual()) { error in
            XCTAssertEqual(error as? FocusControllerError, .deactivationFailed)
        }
        XCTAssertTrue(controller.isActive, "Session must stay active if restrictions could not be removed")
        XCTAssertFalse(try sessionRepo.fetchActive().isEmpty)
    }

    // MARK: - Strategy selection

    func testNormalModeUsesShieldStrategy() {
        XCTAssertEqual(TestSupport.makeMode(name: "N").restrictionStrategy, .shield)
    }

    func testSecurityModeUsesBlockedApplicationsStrategy() {
        let mode = Mode(name: "Bank", isSecurityMode: true)
        XCTAssertEqual(mode.restrictionStrategy, .blockedApplications)
        XCTAssertTrue(mode.isNFCLocked)
    }

    func testStrictOnlyModeUsesShieldButIsLocked() {
        let mode = Mode(name: "Deep", isStrictMode: true)
        XCTAssertEqual(mode.restrictionStrategy, .shield)
        XCTAssertTrue(mode.isNFCLocked)
    }
}

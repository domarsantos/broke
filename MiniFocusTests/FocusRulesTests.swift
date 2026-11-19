//
//  FocusRulesTests.swift
//  MiniFocusTests
//

import XCTest
@testable import MiniFocus

final class FocusRulesTests: XCTestCase {
    private let modeAID = UUID()
    private let modeBID = UUID()

    private func mode(id: UUID, strict: Bool = false, security: Bool = false) -> Mode {
        Mode(id: id, name: "M", isStrictMode: strict, isSecurityMode: security)
    }

    private func tag(linkedTo modeID: UUID?) -> FocusTag {
        FocusTag(hardwareIdentifier: "UID", name: "T", linkedModeID: modeID)
    }

    private func activeSession(mode: UUID) -> FocusSession {
        FocusSession(modeID: mode, trigger: .nfc, status: .active)
    }

    // MARK: - Scan resolution (unlocked, baseline behaviour preserved)

    func testUnregisteredTag() {
        let action = FocusRules.action(tag: nil, activeSession: nil, activeMode: nil, fallbackModeID: modeAID)
        XCTAssertEqual(action, .unregistered)
    }

    func testNoSessionActivatesLinkedMode() {
        let t = tag(linkedTo: modeAID)
        let action = FocusRules.action(tag: t, activeSession: nil, activeMode: nil, fallbackModeID: nil)
        XCTAssertEqual(action, .activate(modeID: modeAID, tagID: t.id))
    }

    func testNoSessionUsesFallbackWhenTagHasNoMode() {
        let t = tag(linkedTo: nil)
        let action = FocusRules.action(tag: t, activeSession: nil, activeMode: nil, fallbackModeID: modeBID)
        XCTAssertEqual(action, .activate(modeID: modeBID, tagID: t.id))
    }

    func testNoSessionNoModeToActivate() {
        let t = tag(linkedTo: nil)
        let action = FocusRules.action(tag: t, activeSession: nil, activeMode: nil, fallbackModeID: nil)
        XCTAssertEqual(action, .noModeToActivate)
    }

    func testSameModeDeactivates() {
        let t = tag(linkedTo: modeAID)
        let action = FocusRules.action(
            tag: t,
            activeSession: activeSession(mode: modeAID),
            activeMode: mode(id: modeAID),
            fallbackModeID: nil
        )
        XCTAssertEqual(action, .deactivate)
    }

    func testDifferentModeSwitchesWhenUnlocked() {
        let t = tag(linkedTo: modeBID)
        let action = FocusRules.action(
            tag: t,
            activeSession: activeSession(mode: modeAID),
            activeMode: mode(id: modeAID),
            fallbackModeID: nil
        )
        XCTAssertEqual(action, .switchTo(modeID: modeBID, tagID: t.id))
    }

    func testUnlinkedTagDeactivatesRunningSession() {
        let t = tag(linkedTo: nil)
        let action = FocusRules.action(
            tag: t,
            activeSession: activeSession(mode: modeAID),
            activeMode: mode(id: modeAID),
            fallbackModeID: modeBID
        )
        XCTAssertEqual(action, .deactivate)
    }

    // MARK: - Locked session scan rules

    func testLockedSessionDifferentModeTagIsDenied() {
        let t = tag(linkedTo: modeBID)
        let action = FocusRules.action(
            tag: t,
            activeSession: activeSession(mode: modeAID),
            activeMode: mode(id: modeAID, strict: true),
            fallbackModeID: nil
        )
        XCTAssertEqual(action, .denied(.lockedDifferentModeTag))
    }

    func testLockedSessionSameModeTagDeactivates() {
        let t = tag(linkedTo: modeAID)
        let action = FocusRules.action(
            tag: t,
            activeSession: activeSession(mode: modeAID),
            activeMode: mode(id: modeAID, security: true),
            fallbackModeID: nil
        )
        XCTAssertEqual(action, .deactivate)
    }

    func testLockedSessionUnlinkedTagDeactivates() {
        let t = tag(linkedTo: nil)
        let action = FocusRules.action(
            tag: t,
            activeSession: activeSession(mode: modeAID),
            activeMode: mode(id: modeAID, strict: true),
            fallbackModeID: nil
        )
        XCTAssertEqual(action, .deactivate)
    }

    // MARK: - Manual stop policy

    func testCanStopManuallyWhenUnlocked() {
        XCTAssertTrue(FocusRules.canStopManually(activeMode: mode(id: modeAID)))
    }

    func testCannotStopManuallyWhenStrict() {
        XCTAssertFalse(FocusRules.canStopManually(activeMode: mode(id: modeAID, strict: true)))
    }

    func testCannotStopManuallyWhenSecurity() {
        XCTAssertFalse(FocusRules.canStopManually(activeMode: mode(id: modeAID, security: true)))
    }

    // MARK: - Anti-lockout start guard

    func testUnlockedModeCanAlwaysStart() {
        XCTAssertTrue(FocusRules.canStartLockedMode(mode(id: modeAID), availableTags: []))
    }

    func testLockedModeCannotStartWithoutAuthorizedTag() {
        let otherTag = FocusTag(hardwareIdentifier: "X", name: "Other", linkedModeID: modeBID)
        XCTAssertFalse(FocusRules.canStartLockedMode(mode(id: modeAID, strict: true), availableTags: [otherTag]))
    }

    func testLockedModeCanStartWithLinkedTag() {
        let linked = FocusTag(hardwareIdentifier: "X", name: "Mine", linkedModeID: modeAID)
        XCTAssertTrue(FocusRules.canStartLockedMode(mode(id: modeAID, security: true), availableTags: [linked]))
    }

    func testLockedModeCanStartWithUnlinkedTag() {
        let unlinked = FocusTag(hardwareIdentifier: "X", name: "Any", linkedModeID: nil)
        XCTAssertTrue(FocusRules.canStartLockedMode(mode(id: modeAID, strict: true), availableTags: [unlinked]))
    }

    func testTagAuthorization() {
        let m = mode(id: modeAID, strict: true)
        XCTAssertTrue(FocusRules.tagIsAuthorized(tag(linkedTo: nil), forActiveMode: m))
        XCTAssertTrue(FocusRules.tagIsAuthorized(tag(linkedTo: modeAID), forActiveMode: m))
        XCTAssertFalse(FocusRules.tagIsAuthorized(tag(linkedTo: modeBID), forActiveMode: m))
    }
}

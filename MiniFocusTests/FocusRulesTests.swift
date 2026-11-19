//
//  FocusRulesTests.swift
//  MiniFocusTests
//

import XCTest
@testable import MiniFocus

final class FocusRulesTests: XCTestCase {
    private let modeA = UUID()
    private let modeB = UUID()

    private func tag(linkedTo modeID: UUID?) -> FocusTag {
        FocusTag(hardwareIdentifier: "UID", name: "T", linkedModeID: modeID)
    }

    private func activeSession(mode: UUID) -> FocusSession {
        FocusSession(modeID: mode, trigger: .nfc, status: .active)
    }

    func testUnregisteredTag() {
        let action = FocusRules.action(tag: nil, activeSession: nil, fallbackModeID: modeA)
        XCTAssertEqual(action, .unregistered)
    }

    func testNoSessionActivatesLinkedMode() {
        let t = tag(linkedTo: modeA)
        let action = FocusRules.action(tag: t, activeSession: nil, fallbackModeID: nil)
        XCTAssertEqual(action, .activate(modeID: modeA, tagID: t.id))
    }

    func testNoSessionUsesFallbackWhenTagHasNoMode() {
        let t = tag(linkedTo: nil)
        let action = FocusRules.action(tag: t, activeSession: nil, fallbackModeID: modeB)
        XCTAssertEqual(action, .activate(modeID: modeB, tagID: t.id))
    }

    func testNoSessionNoModeToActivate() {
        let t = tag(linkedTo: nil)
        let action = FocusRules.action(tag: t, activeSession: nil, fallbackModeID: nil)
        XCTAssertEqual(action, .noModeToActivate)
    }

    func testSameModeDeactivates() {
        let t = tag(linkedTo: modeA)
        let action = FocusRules.action(tag: t, activeSession: activeSession(mode: modeA), fallbackModeID: nil)
        XCTAssertEqual(action, .deactivate)
    }

    func testDifferentModeSwitches() {
        let t = tag(linkedTo: modeB)
        let action = FocusRules.action(tag: t, activeSession: activeSession(mode: modeA), fallbackModeID: nil)
        XCTAssertEqual(action, .switchTo(modeID: modeB, tagID: t.id))
    }

    func testUnlinkedTagDeactivatesRunningSession() {
        let t = tag(linkedTo: nil)
        let action = FocusRules.action(tag: t, activeSession: activeSession(mode: modeA), fallbackModeID: modeB)
        XCTAssertEqual(action, .deactivate)
    }
}

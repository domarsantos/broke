//
//  FakeScreenTimeService.swift
//  BrokeTests
//

import Foundation
import FamilyControls
@testable import Broke

final class FakeScreenTimeService: ScreenTimeServiceProtocol {
    private(set) var appliedModes: [Mode] = []
    private(set) var clearCount = 0
    var isAuthorized: Bool = true

    func authorizationStatus() -> AuthorizationStatus { .approved }
    func authorize() async throws {}

    func apply(_ mode: Mode) {
        appliedModes.append(mode)
    }

    func clearRestrictions() {
        clearCount += 1
    }

    var lastAppliedMode: Mode? { appliedModes.last }
}

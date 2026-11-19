//
//  FakeScreenTimeService.swift
//  MiniFocusTests
//

import Foundation
import FamilyControls
@testable import MiniFocus

final class FakeScreenTimeService: ScreenTimeServiceProtocol {
    var isAuthorized: Bool = true
    /// Inject a failure to simulate ManagedSettings not applying.
    var activateError: Error?
    var deactivateError: Error?

    private(set) var activatedModes: [Mode] = []
    private(set) var deactivatedModes: [Mode] = []
    private(set) var reconciledModes: [Mode?] = []
    private(set) var clearCount = 0

    func authorizationStatus() -> AuthorizationStatus { isAuthorized ? .approved : .notDetermined }
    func authorize() async throws {}

    func activate(_ mode: Mode) throws {
        guard isAuthorized else { throw ScreenTimeError.notAuthorized }
        if let activateError { throw activateError }
        if mode.isSecurityMode && mode.selectedApplications.isEmpty {
            throw ScreenTimeError.securityNeedsApplications
        }
        activatedModes.append(mode)
    }

    func deactivate(_ mode: Mode) throws {
        if let deactivateError { throw deactivateError }
        deactivatedModes.append(mode)
        clearCount += 1
    }

    func reconcile(activeMode: Mode?) throws {
        reconciledModes.append(activeMode)
        if let mode = activeMode {
            try activate(mode)
        } else {
            clearCount += 1
        }
    }

    /// Convenience used by tests written against the previous shield-only API.
    var lastAppliedMode: Mode? { activatedModes.last }
}

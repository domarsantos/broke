//
//  ScreenTimeService.swift
//  MiniFocus
//
//  Owns all FamilyControls / ManagedSettings interaction. Views and domain
//  logic never touch ManagedSettingsStore directly.
//
//  Two stores are used, intentionally:
//  - the *default* store keeps the Focus shield (and stays compatible with any
//    shield applied by the previous v0.1 build);
//  - a *named* "MiniSecurity" store holds only `application.blockedApplications`
//    for Modo Segurança, so the two mechanisms never clobber each other and can
//    be cleared independently (we never call `clearAllSettings()`).
//

import Foundation
import FamilyControls
import ManagedSettings

enum ScreenTimeError: Error, Equatable {
    case notAuthorized
    /// Modo Segurança requires at least one application.
    case securityNeedsApplications
    /// Settings were written but a read-back did not reflect them.
    case applyVerificationFailed
    /// A clear was requested but a read-back still found restrictions.
    case clearVerificationFailed
}

protocol ScreenTimeServiceProtocol {
    var isAuthorized: Bool { get }
    func authorizationStatus() -> AuthorizationStatus
    func authorize() async throws

    /// Apply the restrictions described by a Mode, choosing the shield or the
    /// Security (blockedApplications) strategy. Throws if authorization is
    /// missing, the Mode is invalid for its strategy, or a read-back fails.
    func activate(_ mode: Mode) throws

    /// Remove the restrictions for a Mode (clears both stores defensively) and
    /// verifies the clear actually took effect.
    func deactivate(_ mode: Mode) throws

    /// Reconcile the device state with the expected active Mode without
    /// re-applying when the state already matches. Pass `nil` to ensure nothing
    /// is restricted. Safe to call on every launch.
    func reconcile(activeMode: Mode?) throws
}

final class ScreenTimeService: ScreenTimeServiceProtocol {
    /// Default store: Focus shield. Keeps v0.1 shields under this app's control.
    private let shieldStore = ManagedSettingsStore()
    /// Named store: only ever holds `application.blockedApplications`.
    private let securityStore = ManagedSettingsStore(
        named: ManagedSettingsStore.Name("MiniSecurity")
    )
    private let center = AuthorizationCenter.shared

    var isAuthorized: Bool {
        center.authorizationStatus == .approved
    }

    func authorizationStatus() -> AuthorizationStatus {
        center.authorizationStatus
    }

    func authorize() async throws {
        try await center.requestAuthorization(for: .individual)
    }

    // MARK: - Activate

    func activate(_ mode: Mode) throws {
        guard isAuthorized else { throw ScreenTimeError.notAuthorized }
        switch mode.restrictionStrategy {
        case .shield:
            try applyShield(mode)
        case .blockedApplications:
            try applySecurity(mode)
        }
    }

    private func applyShield(_ mode: Mode) throws {
        let apps = mode.selectedApplications
        let categories = mode.selectedCategories
        let webDomains = mode.selectedWebDomains

        NSLog("ScreenTimeService: applying shield for \(mode.name) [apps: \(apps.count), categories: \(categories.count), web: \(webDomains.count)]")

        // A shield Mode and a security Mode are mutually exclusive (one session
        // at a time), so make sure the Security store is empty.
        clearSecurityStore()

        shieldStore.shield.applications = apps.isEmpty ? nil : apps
        shieldStore.shield.applicationCategories = categories.isEmpty
            ? ShieldSettings.ActivityCategoryPolicy.none
            : .specific(categories)
        shieldStore.shield.webDomains = webDomains.isEmpty ? nil : webDomains
        shieldStore.shield.webDomainCategories = categories.isEmpty
            ? ShieldSettings.ActivityCategoryPolicy.none
            : .specific(categories)

        // Setters don't throw: verify by reading the primary key back.
        let wantApps = apps.isEmpty ? nil : apps
        guard shieldStore.shield.applications == wantApps else {
            throw ScreenTimeError.applyVerificationFailed
        }
    }

    private func applySecurity(_ mode: Mode) throws {
        let apps = mode.selectedApplications
        guard !apps.isEmpty else { throw ScreenTimeError.securityNeedsApplications }

        NSLog("ScreenTimeService: applying security (blockedApplications) for \(mode.name) [apps: \(apps.count)]")

        // Security hides apps via a dedicated store; make sure the shield store
        // is not simultaneously restricting.
        clearShieldStore()

        let blocked = Set(apps.map { Application(token: $0) })
        securityStore.application.blockedApplications = blocked

        guard securityStore.application.blockedApplications == blocked else {
            throw ScreenTimeError.applyVerificationFailed
        }
    }

    // MARK: - Deactivate

    func deactivate(_ mode: Mode) throws {
        NSLog("ScreenTimeService: deactivating \(mode.name)")
        clearShieldStore()
        clearSecurityStore()
        try verifyCleared()
    }

    // MARK: - Reconcile

    func reconcile(activeMode: Mode?) throws {
        // Without authorization we cannot read or write ManagedSettings; leave
        // whatever the system persisted untouched.
        guard isAuthorized else { return }

        guard let mode = activeMode else {
            if !isEverythingCleared {
                clearShieldStore()
                clearSecurityStore()
                try verifyCleared()
            }
            return
        }

        if needsApply(for: mode) {
            try activate(mode)
        }
    }

    /// True when the device state already matches `mode`, so we can skip writes.
    private func needsApply(for mode: Mode) -> Bool {
        switch mode.restrictionStrategy {
        case .shield:
            let want = mode.selectedApplications.isEmpty ? nil : mode.selectedApplications
            return shieldStore.shield.applications != want
                || securityStore.application.blockedApplications != nil
        case .blockedApplications:
            let want = Set(mode.selectedApplications.map { Application(token: $0) })
            return securityStore.application.blockedApplications != want
                || shieldStore.shield.applications != nil
        }
    }

    // MARK: - Clearing helpers (targeted, never clearAllSettings)

    private func clearShieldStore() {
        shieldStore.shield.applications = nil
        shieldStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.none
        shieldStore.shield.webDomains = nil
        shieldStore.shield.webDomainCategories = ShieldSettings.ActivityCategoryPolicy.none
    }

    private func clearSecurityStore() {
        securityStore.application.blockedApplications = nil
    }

    private var isEverythingCleared: Bool {
        shieldStore.shield.applications == nil
            && securityStore.application.blockedApplications == nil
    }

    private func verifyCleared() throws {
        guard isEverythingCleared else {
            throw ScreenTimeError.clearVerificationFailed
        }
    }
}

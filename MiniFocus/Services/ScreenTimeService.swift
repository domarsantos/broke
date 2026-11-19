//
//  ScreenTimeService.swift
//  MiniFocus
//
//  Owns all FamilyControls / ManagedSettings interaction. Views and domain
//  logic never touch ManagedSettingsStore directly.
//

import Foundation
import FamilyControls
import ManagedSettings

protocol ScreenTimeServiceProtocol {
    var isAuthorized: Bool { get }
    func authorizationStatus() -> AuthorizationStatus
    func authorize() async throws
    /// Apply the restrictions described by a Mode.
    func apply(_ mode: Mode)
    /// Remove all restrictions managed by this app.
    func clearRestrictions()
}

final class ScreenTimeService: ScreenTimeServiceProtocol {
    /// Uses the default ManagedSettingsStore so shields already applied by the
    /// previous (v0.1) build remain under this app's control after upgrade.
    private let store = ManagedSettingsStore()
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

    func apply(_ mode: Mode) {
        let apps = mode.selectedApplications
        let categories = mode.selectedCategories
        let webDomains = mode.selectedWebDomains

        NSLog("ScreenTimeService: applying mode \(mode.name) [apps: \(apps.count), categories: \(categories.count), web: \(webDomains.count)]")

        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = categories.isEmpty
            ? ShieldSettings.ActivityCategoryPolicy.none
            : .specific(categories)
        store.shield.webDomains = webDomains.isEmpty ? nil : webDomains
        store.shield.webDomainCategories = categories.isEmpty
            ? ShieldSettings.ActivityCategoryPolicy.none
            : .specific(categories)
    }

    func clearRestrictions() {
        NSLog("ScreenTimeService: clearing restrictions")
        store.shield.applications = nil
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.none
        store.shield.webDomains = nil
        store.shield.webDomainCategories = ShieldSettings.ActivityCategoryPolicy.none
    }
}

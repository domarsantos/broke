//
//  Mode.swift
//  MiniFocus
//
//  A Mode represents a focus context (Work, Study, Sleep, ...).
//  It replaces the legacy `Profile` concept.
//

import Foundation
import FamilyControls
import ManagedSettings

/// How a Mode enforces its restrictions.
///
/// - `shield`: the default Focus behaviour. Selected apps/categories/sites are
///   shielded (the app still appears but is intercepted by a shield screen).
/// - `blockedApplications`: Modo Segurança. Selected apps are hidden entirely
///   via `ManagedSettings.ApplicationSettings.blockedApplications`.
enum RestrictionStrategy: Equatable {
    case shield
    case blockedApplications
}

/// Domain model for a focus context.
///
/// The Apple `FamilyActivitySelection` is stored as-is because it is the only
/// safe, forward-compatible container for application/category/web tokens.
/// We never serialize the opaque tokens by hand.
struct Mode: Identifiable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var selection: FamilyActivitySelection
    /// Strict Mode: once active it cannot be stopped manually from the Mini.
    /// Only an authorized Mini Tag can end the session.
    var isStrictMode: Bool
    /// Modo Segurança: hides the selected apps completely (blockedApplications)
    /// and is always NFC-gated, regardless of `isStrictMode`.
    var isSecurityMode: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "bell.slash",
        selection: FamilyActivitySelection = FamilyActivitySelection(),
        isStrictMode: Bool = false,
        isSecurityMode: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.selection = selection
        self.isStrictMode = isStrictMode
        self.isSecurityMode = isSecurityMode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Lock / strategy (centralized domain policy)

    /// A Mode is NFC-locked when it cannot be ended manually by tapping in the
    /// Mini. Both Strict and Security modes are locked; Security is always
    /// locked even if `isStrictMode` is false.
    var isNFCLocked: Bool {
        isStrictMode || isSecurityMode
    }

    /// Which ManagedSettings mechanism enforces this Mode. Security takes
    /// precedence so sensitive apps are hidden rather than merely shielded.
    var restrictionStrategy: RestrictionStrategy {
        isSecurityMode ? .blockedApplications : .shield
    }

    // MARK: - Convenience accessors over the FamilyControls selection

    var selectedApplications: Set<ApplicationToken> {
        selection.applicationTokens
    }

    var selectedCategories: Set<ActivityCategoryToken> {
        selection.categoryTokens
    }

    var selectedWebDomains: Set<WebDomainToken> {
        selection.webDomainTokens
    }

    /// True when this Mode would not restrict anything.
    var isEmpty: Bool {
        selectedApplications.isEmpty
            && selectedCategories.isEmpty
            && selectedWebDomains.isEmpty
    }
}

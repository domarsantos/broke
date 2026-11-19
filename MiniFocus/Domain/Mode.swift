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
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "bell.slash",
        selection: FamilyActivitySelection = FamilyActivitySelection(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.selection = selection
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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

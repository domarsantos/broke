//
//  TestSupport.swift
//  MiniFocusTests
//

import Foundation
import SwiftData
import FamilyControls
@testable import MiniFocus

@MainActor
enum TestSupport {
    static func inMemoryContext() -> ModelContext {
        ModelContext(PersistenceController.makeInMemoryContainer())
    }

    static func makeMode(name: String = "Work", icon: String = "briefcase") -> Mode {
        Mode(name: name, icon: icon, selection: FamilyActivitySelection())
    }

    static func makeTag(
        hardwareIdentifier: String? = "04A1B2C3",
        name: String = "Office",
        linkedModeID: UUID? = nil
    ) -> FocusTag {
        FocusTag(hardwareIdentifier: hardwareIdentifier, name: name, linkedModeID: linkedModeID)
    }
}

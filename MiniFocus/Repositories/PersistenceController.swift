//
//  PersistenceController.swift
//  MiniFocus
//
//  Builds the SwiftData ModelContainer used by the local repositories.
//

import Foundation
import SwiftData

enum PersistenceController {
    /// Shared on-disk container stored at an explicit Application Support URL.
    /// When extensions are added later, point this at an App Group URL instead.
    static func makeSharedContainer() -> ModelContainer {
        let schema = Schema(versionedSchema: BrokeSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, url: sharedStoreURL())
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: BrokeMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// Resolves (and creates if needed) the on-disk store location.
    private static func sharedStoreURL() -> URL {
        let fileManager = FileManager.default
        let base = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory
        return base.appendingPathComponent("Broke.store")
    }

    /// In-memory container for unit tests and previews.
    static func makeInMemoryContainer() -> ModelContainer {
        let schema = Schema(versionedSchema: BrokeSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }

    /// On-disk container at an explicit URL (used by tests to simulate relaunch).
    static func makeContainer(at url: URL) -> ModelContainer {
        let schema = Schema(versionedSchema: BrokeSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, url: url)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: BrokeMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer at \(url): \(error)")
        }
    }
}

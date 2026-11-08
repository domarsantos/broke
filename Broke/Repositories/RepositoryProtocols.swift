//
//  RepositoryProtocols.swift
//  Broke
//
//  Persistence abstractions. Domain and UI depend only on these protocols,
//  never on the concrete (SwiftData) implementation. This is the seam that
//  will later allow a Cloud* implementation without touching Views or rules.
//

import Foundation

protocol ModeRepositoryProtocol {
    func fetchAll() throws -> [Mode]
    func fetch(id: UUID) throws -> Mode?
    func create(_ mode: Mode) throws
    func update(_ mode: Mode) throws
    func delete(id: UUID) throws
}

protocol TagRepositoryProtocol {
    func fetchAll() throws -> [FocusTag]
    func fetch(id: UUID) throws -> FocusTag?
    /// Look up a registered tag by its physical identifier (UID).
    func fetch(hardwareIdentifier: String) throws -> FocusTag?
    func register(_ tag: FocusTag) throws
    func update(_ tag: FocusTag) throws
    func delete(id: UUID) throws
    /// Remove the link to a given Mode from any tags that reference it.
    func unlinkMode(_ modeID: UUID) throws
}

protocol SessionRepositoryProtocol {
    func fetchAll() throws -> [FocusSession]
    func fetch(id: UUID) throws -> FocusSession?
    /// All sessions still marked active (normally zero or one).
    func fetchActive() throws -> [FocusSession]
    func create(_ session: FocusSession) throws
    func update(_ session: FocusSession) throws
    func delete(id: UUID) throws
}

//
//  KGGExerciseRepository.swift
//  Agil
//
//  Repository Protocol für KGG-Übungen (Domain Layer).
//  Abstrahiert Storage-Details.
//

import Foundation

public protocol KGGExerciseRepository: Sendable {
    
    func save(_ exercise: KGGScannedExercise) async throws
    
    func fetchVisibleExercises() async throws -> [KGGScannedExercise]
    func fetchAll() async throws -> [KGGScannedExercise]
    func fetch(id: UUID) async throws -> KGGScannedExercise?
    func fetchByExerciseId(_ exerciseId: UUID) async throws -> [KGGScannedExercise]
    
    func updateDownloadStatus(_ exerciseId: UUID, downloaded: Bool) async throws
    func markCompleted(_ exerciseId: UUID) async throws
    
    func delete(_ exerciseId: UUID) async throws
    func deleteExpired() async throws
    func deleteAll() async throws
}

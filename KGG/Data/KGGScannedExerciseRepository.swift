//
//  KGGScannedExerciseRepository.swift
//  Agil
//
//  SwiftData-Implementierung von KGGExerciseRepository.
//

import Foundation
import SwiftData

@MainActor
public final class KGGScannedExerciseRepository: KGGExerciseRepository {
    
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    public func save(_ exercise: KGGScannedExercise) async throws {
        let model = KGGScannedExerciseModel.from(exercise)
        
        // Fetch all und filter in Swift (nicht im Predicate)
        let descriptor = FetchDescriptor<KGGScannedExerciseModel>()
        let allModels = try modelContext.fetch(descriptor)
        
        if let existing = allModels.first(where: { $0.id == exercise.id }) {
            modelContext.delete(existing)
        }
        
        modelContext.insert(model)
        try modelContext.save()
    }
    
    public func fetchVisibleExercises() async throws -> [KGGScannedExercise] {
        let now = Date()
        let descriptor = FetchDescriptor<KGGScannedExerciseModel>(
            sortBy: [SortDescriptor(\.scannedAt, order: .reverse)]
        )
        let allModels = try modelContext.fetch(descriptor)
        let filtered = allModels.filter { $0.expiresAt > now && !$0.isCompleted }
        return filtered.map { $0.toDomain() }
    }
    
    public func fetchAll() async throws -> [KGGScannedExercise] {
        let descriptor = FetchDescriptor<KGGScannedExerciseModel>(
            sortBy: [SortDescriptor(\.scannedAt, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.map { $0.toDomain() }
    }
    
    public func fetch(id: UUID) async throws -> KGGScannedExercise? {
        let descriptor = FetchDescriptor<KGGScannedExerciseModel>()
        let allModels = try modelContext.fetch(descriptor)
        guard let model = allModels.first(where: { $0.id == id }) else { return nil }
        return model.toDomain()
    }
    
    public func fetchByExerciseId(_ exerciseId: UUID) async throws -> [KGGScannedExercise] {
        let descriptor = FetchDescriptor<KGGScannedExerciseModel>(
            sortBy: [SortDescriptor(\.scannedAt, order: .reverse)]
        )
        let allModels = try modelContext.fetch(descriptor)
        let filtered = allModels.filter { $0.exerciseId == exerciseId }
        return filtered.map { $0.toDomain() }
    }
    
    public func updateDownloadStatus(_ exerciseId: UUID, downloaded: Bool) async throws {
        let descriptor = FetchDescriptor<KGGScannedExerciseModel>()
        let allModels = try modelContext.fetch(descriptor)
        guard let model = allModels.first(where: { $0.id == exerciseId }) else { return }
        model.isVideoDownloaded = downloaded
        try modelContext.save()
    }
    
    public func markCompleted(_ exerciseId: UUID) async throws {
        let descriptor = FetchDescriptor<KGGScannedExerciseModel>()
        let allModels = try modelContext.fetch(descriptor)
        guard let model = allModels.first(where: { $0.id == exerciseId }) else { return }
        model.isCompleted = true
        model.completedAt = Date()
        try modelContext.save()
    }
    
    public func delete(_ exerciseId: UUID) async throws {
        let descriptor = FetchDescriptor<KGGScannedExerciseModel>()
        let allModels = try modelContext.fetch(descriptor)
        guard let model = allModels.first(where: { $0.id == exerciseId }) else { return }
        modelContext.delete(model)
        try modelContext.save()
    }
    
    public func deleteExpired() async throws {
        let now = Date()
        let descriptor = FetchDescriptor<KGGScannedExerciseModel>()
        let allModels = try modelContext.fetch(descriptor)
        let expiredModels = allModels.filter { $0.expiresAt <= now }
        expiredModels.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
    
    public func deleteAll() async throws {
        let descriptor = FetchDescriptor<KGGScannedExerciseModel>()
        let allModels = try modelContext.fetch(descriptor)
        allModels.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}

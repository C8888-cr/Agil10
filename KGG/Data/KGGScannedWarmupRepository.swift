//
//  KGGScannedWarmupRepository.swift
//  Agil10
//
//  Created by Christiane Roth on 13.07.26.
//


//
//  KGGScannedWarmupRepository.swift
//  Agil
//
//  SwiftData-Implementierung von KGGWarmupRepository.
//

import Foundation
import SwiftData

@MainActor
public final class KGGScannedWarmupRepository: KGGWarmupRepository {

    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func replaceAll(_ warmups: [KGGScannedWarmup]) async throws {
        let descriptor = FetchDescriptor<KGGScannedWarmupModel>()
        let existing = try modelContext.fetch(descriptor)
        existing.forEach { modelContext.delete($0) }

        for warmup in warmups {
            modelContext.insert(KGGScannedWarmupModel.from(warmup))
        }

        try modelContext.save()
    }

    public func fetchVisible() async throws -> [KGGScannedWarmup] {
        let now = Date()
        let descriptor = FetchDescriptor<KGGScannedWarmupModel>(
            sortBy: [SortDescriptor(\.order)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.filter { $0.expiresAt > now }.map { $0.toDomain() }
    }

    public func deleteExpired() async throws {
        let now = Date()
        let descriptor = FetchDescriptor<KGGScannedWarmupModel>()
        let models = try modelContext.fetch(descriptor)
        models.filter { $0.expiresAt <= now }.forEach { modelContext.delete($0) }
        try modelContext.save()
    }

    public func deleteAll() async throws {
        let descriptor = FetchDescriptor<KGGScannedWarmupModel>()
        let models = try modelContext.fetch(descriptor)
        models.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}
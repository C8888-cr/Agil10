//
//  WorkoutLogRepository.swift
//  Agil10.0
//
//  Created by Christiane Roth on 01.06.26.
//


//
//  WorkoutLogRepository.swift
//  Agil
//
//  SwiftData-Implementierung von WorkoutLogRepositoryProtocol.
//  Folgt dem Pattern von VideoScheduleRepository (modelContext injiziert).
//

import Foundation
import SwiftData

@MainActor
final class WorkoutLogRepository: WorkoutLogRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Insert

    func insert(_ log: WorkoutLog) throws {
        modelContext.insert(log)
        try modelContext.save()
    }

    // MARK: - Fetch

    func fetchAll(userId: UUID) throws -> [WorkoutLog] {
        let descriptor = FetchDescriptor<WorkoutLog>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchByVideo(videoId: UUID, userId: UUID) throws -> [WorkoutLog] {
        let descriptor = FetchDescriptor<WorkoutLog>(
            predicate: #Predicate {
                $0.userId == userId && $0.videoId == videoId
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(from startDate: Date, to endDate: Date, userId: UUID) throws -> [WorkoutLog] {
        let descriptor = FetchDescriptor<WorkoutLog>(
            predicate: #Predicate {
                $0.userId == userId
                && $0.date >= startDate
                && $0.date < endDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Bulk Delete (DSGVO)

    func deleteAll(for userId: UUID) throws {
        let descriptor = FetchDescriptor<WorkoutLog>(
            predicate: #Predicate { $0.userId == userId }
        )
        let logs = try modelContext.fetch(descriptor)
        logs.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}
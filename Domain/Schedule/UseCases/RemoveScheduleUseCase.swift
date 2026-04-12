//
//  RemoveScheduleUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import Foundation

@MainActor
final class RemoveScheduleUseCase {
    private let repository: VideoScheduleRepositoryProtocol

    init(repository: VideoScheduleRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ schedule: VideoSchedule, userId: UUID) throws {
        let date = schedule.scheduledDate
        try repository.delete(schedule)

        // Indizes neu ordnen
        let remaining = try repository.fetchSchedules(for: date, userId: userId)
            .sorted { $0.orderIndex < $1.orderIndex }

        for (index, s) in remaining.enumerated() {
            s.orderIndex = index
        }
        try repository.saveChanges()
    }
}

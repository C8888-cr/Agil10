//
//  GetSchedulesForDateUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import Foundation


@MainActor
final class GetSchedulesForDateUseCase {
    private let repository: VideoScheduleRepositoryProtocol

    init(repository: VideoScheduleRepositoryProtocol) {
        self.repository = repository
    }

    func execute(date: Date, userId: UUID) throws -> [VideoSchedule] {
        try repository.fetchSchedules(for: date, userId: userId)
    }
}

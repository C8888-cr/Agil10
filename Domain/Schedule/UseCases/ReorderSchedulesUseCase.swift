//
//  ReorderSchedulesUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import Foundation

@MainActor
final class ReorderSchedulesUseCase {
    private let repository: VideoScheduleRepositoryProtocol

    init(repository: VideoScheduleRepositoryProtocol) {
        self.repository = repository
    }

    func execute(schedules: inout [VideoSchedule], from source: IndexSet, to destination: Int) throws {
        schedules.move(fromOffsets: source, toOffset: destination)
        for (index, schedule) in schedules.enumerated() {
            schedule.orderIndex = index
        }
        try repository.saveChanges()
    }
}

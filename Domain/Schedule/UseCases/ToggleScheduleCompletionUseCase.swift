//
//  ToggleScheduleCompletionUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import Foundation

@MainActor
final class ToggleScheduleCompletionUseCase {
    private let repository: VideoScheduleRepositoryProtocol

    init(repository: VideoScheduleRepositoryProtocol) {
        self.repository = repository
    }

    func toggle(_ schedule: VideoSchedule) throws {
        schedule.isCompleted.toggle()
        schedule.completedAt = schedule.isCompleted ? Date() : nil
        if !schedule.isCompleted { schedule.rating = nil }
        try repository.saveChanges()
    }

    func markCompleted(_ schedule: VideoSchedule, rating: Int? = nil) throws {
        schedule.isCompleted = true
        schedule.completedAt = Date()
        schedule.rating = rating
        try repository.saveChanges()
    }

    func markIncomplete(_ schedule: VideoSchedule) throws {
        schedule.isCompleted = false
        schedule.completedAt = nil
        schedule.rating = nil
        try repository.saveChanges()
    }
    func saveChanges() throws {
        try repository.saveChanges()
    }
}

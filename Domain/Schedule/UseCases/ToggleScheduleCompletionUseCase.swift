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
    private let writeWorkoutLogUseCase: WriteWorkoutLogUseCase

    init(
        repository: VideoScheduleRepositoryProtocol,
        writeWorkoutLogUseCase: WriteWorkoutLogUseCase
    ) {
        self.repository = repository
        self.writeWorkoutLogUseCase = writeWorkoutLogUseCase
    }

    func toggle(_ schedule: VideoSchedule) throws {
        let wasCompleted = schedule.isCompleted
        let originalModusRaw = schedule.completedModusRaw

        schedule.isCompleted.toggle()
        schedule.completedAt = schedule.isCompleted ? Date() : nil

        if !schedule.isCompleted {
            // → markIncomplete-Pfad
            schedule.rating = nil
            schedule.completedModusRaw = nil
            try repository.saveChanges()

            // Korrektur-Eintrag, wenn vorher abgeschlossen war
            if wasCompleted {
                try writeWorkoutLogUseCase.logCorrection(
                    for: schedule,
                    originalModusRaw: originalModusRaw
                )
            }
        } else {
            // → markCompleted-Pfad
            let prefs = try repository.fetchUserPreferences(for: schedule.user?.id ?? UUID())
            schedule.completedModusRaw = (prefs?.workoutModus ?? .standard).rawValue
            try repository.saveChanges()

            try writeWorkoutLogUseCase.logCompletion(from: schedule)
        }
    }

    func markCompleted(_ schedule: VideoSchedule, rating: Int? = nil) throws {
        schedule.isCompleted = true
        schedule.completedAt = Date()
        schedule.rating = rating

        // Modus zur Erledigungszeit einbrennen
        let prefs = try repository.fetchUserPreferences(for: schedule.user?.id ?? UUID())
        schedule.completedModusRaw = (prefs?.workoutModus ?? .standard).rawValue

        try repository.save(schedule)
        try writeWorkoutLogUseCase.logCompletion(from: schedule)
    }

    func markIncomplete(_ schedule: VideoSchedule) throws {
        let wasCompleted = schedule.isCompleted
        let originalModusRaw = schedule.completedModusRaw

        schedule.isCompleted = false
        schedule.completedAt = nil
        schedule.rating = nil
        schedule.completedModusRaw = nil
        try repository.saveChanges()

        // Korrektur-Eintrag nur wenn vorher tatsächlich abgeschlossen war
        if wasCompleted {
            try writeWorkoutLogUseCase.logCorrection(
                for: schedule,
                originalModusRaw: originalModusRaw
            )
        }
    }

    func saveChanges() throws {
        try repository.saveChanges()
    }
}

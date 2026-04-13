//
//  ResetUserDataUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 13.04.26.
//
import Foundation

/// ResetUserDataUseCase.swift
@MainActor
struct ResetUserDataUseCase {
    let scheduleRepository: VideoScheduleRepositoryProtocol
    let userRepository: UserRepository

    func execute(userId: UUID) throws {
        try scheduleRepository.deleteAllSchedules(for: userId)
        try scheduleRepository.deleteAllTemplates(for: userId)
        
        if let prefs = try scheduleRepository.fetchUserPreferences(for: userId) {
            prefs.notificationsEnabled = true
            prefs.reminderTime = Calendar.current.date(
                bySettingHour: 18, minute: 0, second: 0, of: Date()
            ) ?? Date()
            prefs.soundEnabled = true
            prefs.autoPlayNextVideo = false
            prefs.showCompletedExercises = true
            prefs.weekStartsOnMonday = true
            prefs.defaultDailyTrainingMinutes = 30
            prefs.activeDaysRaw = "Mo,Di,Mi,Do,Fr"
            prefs.activeMode = "single"
            prefs.weeklyGoals.forEach { goal in
                goal.targetMinutes = 30
                goal.isActive = true
                goal.reminderEnabled = true
                goal.reminderTime = Calendar.current.date(
                    bySettingHour: 18, minute: 0, second: 0, of: Date()
                ) ?? Date()
                goal.hasIndividualReminderTime = false
                goal.recurrenceRule = .single
                goal.interVideoPauseSeconds = 30
            }
        }
    }
}

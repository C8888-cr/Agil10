//
//  CalculateDailyProgressUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import Foundation

@MainActor
final class CalculateDailyProgressUseCase {
    private let repository: VideoScheduleRepositoryProtocol

    init(repository: VideoScheduleRepositoryProtocol) {
        self.repository = repository
    }

    func execute(for user: User, on date: Date) throws -> DailyProgressResult {
        let allSchedules = try repository.fetchSchedules(for: date, userId: user.id)
        let preferences = try repository.fetchUserPreferences(for: user.id)
        
        let activeMode = preferences?.activeMode ?? "single"
        let expertModeEnabled = preferences?.expertModeEnabled ?? false   // 🆕
        let schedules = allSchedules.filter { $0.planMode == activeMode }
        
        guard let preferences,
              let goal = preferences.getGoalFor(dayOfWeek: dayIndex(for: date)) else {
            return DailyProgressResult(
                schedules: schedules,
                targetMinutes: 0,
                totalScheduledSeconds: 0,
                completedSeconds: 0,
                interVideoPauseSeconds: 0
            )
        }
        
        var totalSeconds = 0
        for (index, schedule) in schedules.enumerated() {
            // 🆕 modus-aware
            totalSeconds += schedule.effectiveDurationSeconds(currentExpertModeEnabled: expertModeEnabled)
            if index < schedules.count - 1 {
                totalSeconds += goal.interVideoPauseSeconds
            }
        }
        
        let completedSchedules = schedules.filter { $0.isCompleted }
        var completedSeconds = 0
        for (index, schedule) in completedSchedules.enumerated() {
            // 🆕 modus-aware (bei isCompleted nimmt es automatisch completedAsExpert)
            completedSeconds += schedule.effectiveDurationSeconds(currentExpertModeEnabled: expertModeEnabled)
            if index < completedSchedules.count - 1 {
                completedSeconds += goal.interVideoPauseSeconds
            }
        }
        
        return DailyProgressResult(
            schedules: schedules,
            targetMinutes: goal.targetMinutes,
            totalScheduledSeconds: totalSeconds,
            completedSeconds: completedSeconds,
            interVideoPauseSeconds: goal.interVideoPauseSeconds
        )
    }
    
    
    
    private func dayIndex(for date: Date) -> Int {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let rawWeekday = calendar.component(.weekday, from: date)
        return (rawWeekday - firstWeekday + 7) % 7
    }
}


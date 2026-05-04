//
//  CalculateWeeklyProgressUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import Foundation

@MainActor
final class CalculateWeeklyProgressUseCase {
    private let repository: VideoScheduleRepositoryProtocol
    
    init(repository: VideoScheduleRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(for user: User) throws -> WeeklyProgressResult {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return WeeklyProgressResult(completedSeconds: 0, targetSeconds: 0)
        }
        
        let schedules = try repository.fetchSchedules(from: weekStart, to: weekEnd, userId: user.id)
        let preferences = try repository.fetchUserPreferences(for: user.id)
        let expertModeEnabled = preferences?.expertModeEnabled ?? false   // 🆕
        
        let completedSeconds = schedules.filter { $0.isCompleted }
            .reduce(0) { sum, schedule in
                // 🆕 modus-aware
                sum + schedule.effectiveDurationSeconds(currentExpertModeEnabled: expertModeEnabled)
            }
        
        guard let preferences else {
            return WeeklyProgressResult(completedSeconds: completedSeconds, targetSeconds: 0)
        }
        
        let weeklyTargetSeconds = (0..<7).compactMap {
            preferences.getGoalFor(dayOfWeek: $0)
        }.reduce(0) { $0 + $1.targetMinutes * 60 }
        
        return WeeklyProgressResult(
            completedSeconds: completedSeconds,
            targetSeconds: weeklyTargetSeconds
        )
    }
}

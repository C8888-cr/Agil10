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
        let schedules = try repository.fetchSchedules(for: date, userId: user.id)
        let preferences = try repository.fetchUserPreferences(for: user.id)

        guard let preferences,
              let goal = preferences.getGoalFor(dayOfWeek: dayIndex(for: date)) else {
            let completed = schedules.filter { $0.isCompleted }.count
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
            totalSeconds += schedule.totalDurationSeconds
            if index < schedules.count - 1 {
                totalSeconds += goal.interVideoPauseSeconds
            }
        }

        let completedSchedules = schedules.filter { $0.isCompleted }
        var completedSeconds = 0
        for (index, schedule) in completedSchedules.enumerated() {
            completedSeconds += schedule.totalDurationSeconds
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


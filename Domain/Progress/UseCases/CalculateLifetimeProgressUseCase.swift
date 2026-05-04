//
//  CalculateLifetimeProgressUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import Foundation

@MainActor
final class CalculateLifetimeProgressUseCase {
    private let repository: VideoScheduleRepositoryProtocol

    init(repository: VideoScheduleRepositoryProtocol) {
        self.repository = repository
    }

    func execute(for user: User) throws -> LifetimeProgressResult {
        let allSchedules = try repository.fetchAllSchedules(userId: user.id)
        let completed = allSchedules.filter { $0.isCompleted }
        let preferences = try repository.fetchUserPreferences(for: user.id)
        let expertModeEnabled = preferences?.expertModeEnabled ?? false   // 🆕
        
        // 🆕 modus-aware
        let totalSeconds = completed.reduce(0) { sum, schedule in
            sum + schedule.effectiveDurationSeconds(currentExpertModeEnabled: expertModeEnabled)
        }
        let totalMinutes = (totalSeconds + 59) / 60
        let streak = calculateStreak(from: allSchedules)
        
        let calendar = Calendar.current
        let uniqueDates = Set(allSchedules.map { calendar.startOfDay(for: $0.scheduledDate) })
        
        let daysWithGoalReached = uniqueDates.filter { date in
            guard let preferences else { return false }
            let firstWeekday = calendar.firstWeekday
            let rawWeekday = calendar.component(.weekday, from: date)
            let dayOfWeek = (rawWeekday - firstWeekday + 7) % 7
            guard let goal = preferences.getGoalFor(dayOfWeek: dayOfWeek) else { return false }
            
            // 🆕 modus-aware
            let completedMinutes = allSchedules
                .filter { $0.isCompleted && calendar.isDate($0.scheduledDate, inSameDayAs: date) }
                .reduce(0) { sum, schedule in
                    sum + schedule.effectiveDurationMinutes(currentExpertModeEnabled: expertModeEnabled)
                }
            return completedMinutes >= goal.targetMinutes
        }
        
        return LifetimeProgressResult(
            completedMinutes: totalMinutes,
            completedWorkouts: completed.count,
            streak: streak,
            lifetimeProgress: uniqueDates.isEmpty ? 0.0 : Double(daysWithGoalReached.count) / Double(uniqueDates.count)
        )
    }

    private func calculateStreak(from schedules: [VideoSchedule]) -> Int {
        let calendar = Calendar.current
        let dateGroups = Dictionary(grouping: schedules) {
            calendar.startOfDay(for: $0.scheduledDate)
        }
        let sortedDates = dateGroups.keys.sorted(by: >)
        guard let mostRecent = sortedDates.first else { return 0 }

        let daysSince = calendar.dateComponents([.day], from: mostRecent, to: Date()).day ?? 999
        if daysSince > 1 { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        while true {
            if let day = dateGroups[checkDate], day.contains(where: { $0.isCompleted }) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else { break }
        }
        return streak
    }
}


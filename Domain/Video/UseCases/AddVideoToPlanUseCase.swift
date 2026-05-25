import Foundation

@MainActor
final class AddVideoToPlanUseCase {
    private let repository: VideoScheduleRepositoryProtocol

    init(repository: VideoScheduleRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        video: Video,
        date: Date,
        user: User,
        planMode: String,
        dayIndex: Int,
        customRepetitions: Int? = nil,
        customPauseSeconds: Int? = nil,
        customLoopDuration: Int? = nil,
        sets: Int? = nil,
        reps: Int? = nil,
        expertPauseSeconds: Int? = nil,
        mobilitySets: Int? = nil,
              mobilityReps: Int? = nil,
              mobilityPauseSeconds: Int? = nil,
        weightKg: Int? = nil
    ) throws {
        guard let userInContext = try repository.fetchUser(by: user.id) else { return }
        guard let videoInContext = try repository.fetchVideo(by: video.id) else { return }
        guard let preferences = try repository.fetchUserPreferences(for: user.id) else { return }

        switch planMode {
        case "daily":
            try addToDaily(
                video: videoInContext,
                date: date,
                user: userInContext,
                preferences: preferences,
                customRepetitions: customRepetitions,
                customPauseSeconds: customPauseSeconds,
                customLoopDuration: customLoopDuration,
                sets: sets,
                reps: reps,
                expertPauseSeconds: expertPauseSeconds,
                mobilitySets: mobilitySets,
                               mobilityReps: mobilityReps,
                               mobilityPauseSeconds: mobilityPauseSeconds,
                weightKg: weightKg
            )

        case "weekly":
            try addToWeekly(
                video: videoInContext,
                date: date,
                user: userInContext,
                preferences: preferences,
                dayIndex: dayIndex,
                customRepetitions: customRepetitions,
                customPauseSeconds: customPauseSeconds,
                customLoopDuration: customLoopDuration,
                sets: sets,
                reps: reps,
                expertPauseSeconds: expertPauseSeconds,
                mobilitySets: mobilitySets,
                               mobilityReps: mobilityReps,
                               mobilityPauseSeconds: mobilityPauseSeconds,
                weightKg: weightKg
            )

        default:
            break
        }
    }

    // MARK: - Daily

    private func addToDaily(
        video: Video,
        date: Date,
        user: User,
        preferences: UserPreferences,
        customRepetitions: Int?,
        customPauseSeconds: Int?,
        customLoopDuration: Int?,
        sets: Int?,
        reps: Int?,
        expertPauseSeconds: Int?,
        mobilitySets: Int? = nil,
              mobilityReps: Int? = nil,
              mobilityPauseSeconds: Int? = nil,
        weightKg: Int?
    ) throws {
        let existing = try repository.fetchTemplates(for: user.id, isWeekly: false)
        let template = VideoSchedule(
            scheduledDate: Date(),
            orderIndex: existing.count,
            video: video,
            customRepetitions: customRepetitions,
            customPauseSeconds: customPauseSeconds,
            customLoopDurationSeconds: customLoopDuration,
            user: user,
            sets: sets,
            reps: reps,
            expertPauseSeconds: expertPauseSeconds,
            mobilitySets: mobilitySets,
                           mobilityReps: mobilityReps,
                           mobilityPauseSeconds: mobilityPauseSeconds
        )
        template.isTemplate = true
        template.isWeeklyTemplate = false
        template.planMode = "daily"
        template.templateUserId = user.id
        template.dayOfWeek = 0
        template.weightKg = weightKg
        try repository.save(template)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let horizon = calendar.date(byAdding: .month, value: 3, to: today)!
        let groupId = UUID()

        let activeDayIndices = preferences.weeklyGoals
            .filter { $0.isActive && $0.targetMinutes > 0 }
            .map { $0.dayOfWeek }

        var current = calendar.startOfDay(for: date)

        while current <= horizon {
            let weekday = calendar.component(.weekday, from: current)
            let currentDayIndex = weekday == 1 ? 6 : weekday - 2

            if activeDayIndices.contains(currentDayIndex) {
                let existing = try repository.fetchSchedules(for: current, userId: user.id)
                let schedule = VideoSchedule(
                    scheduledDate: calendar.startOfDay(for: current),
                    orderIndex: existing.count,
                    video: video,
                    customRepetitions: customRepetitions,
                    customPauseSeconds: customPauseSeconds,
                    customLoopDurationSeconds: customLoopDuration,
                    user: user,
                    sets: sets,
                    reps: reps,
                    expertPauseSeconds: expertPauseSeconds,
                    mobilitySets: mobilitySets,
                                   mobilityReps: mobilityReps,
                                   mobilityPauseSeconds: mobilityPauseSeconds,
                    recurrenceRule: .daily,
                    recurrenceGroupID: groupId
                )
                schedule.isAutoGenerated = true
                schedule.dayOfWeek = currentDayIndex
                schedule.planMode = "daily"
                schedule.weightKg = weightKg
                try repository.save(schedule)
            }

            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
    }

    // MARK: - Weekly

    private func addToWeekly(
        video: Video,
        date: Date,
        user: User,
        preferences: UserPreferences,
        dayIndex: Int,
        customRepetitions: Int?,
        customPauseSeconds: Int?,
        customLoopDuration: Int?,
        sets: Int?,
        reps: Int?,
        expertPauseSeconds: Int?,
        mobilitySets: Int? = nil,
              mobilityReps: Int? = nil,
              mobilityPauseSeconds: Int? = nil,
        weightKg: Int?
    ) throws {
        let existing = try repository.fetchTemplates(for: user.id, isWeekly: true)
        let template = VideoSchedule(
            scheduledDate: Date(),
            orderIndex: existing.count,
            video: video,
            customRepetitions: customRepetitions,
            customPauseSeconds: customPauseSeconds,
            customLoopDurationSeconds: customLoopDuration,
            user: user,
            sets: sets,
            reps: reps,
            expertPauseSeconds: expertPauseSeconds,
            mobilitySets: mobilitySets,
                           mobilityReps: mobilityReps,
                           mobilityPauseSeconds: mobilityPauseSeconds
        )
        template.isTemplate = true
        template.isWeeklyTemplate = true
        template.planMode = "weekly"
        template.templateUserId = user.id
        template.dayOfWeek = dayIndex
        template.weightKg = weightKg
        try repository.save(template)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let horizon = calendar.date(byAdding: .month, value: 3, to: today)!
        let groupId = UUID()
        let targetWeekday = dayIndex == 6 ? 1 : dayIndex + 2

        var current = calendar.startOfDay(for: date)

        while current <= horizon {
            let weekday = calendar.component(.weekday, from: current)
            if weekday == targetWeekday {
                let existing = try repository.fetchSchedules(for: current, userId: user.id)
                let schedule = VideoSchedule(
                    scheduledDate: calendar.startOfDay(for: current),
                    orderIndex: existing.count,
                    video: video,
                    customRepetitions: customRepetitions,
                    customPauseSeconds: customPauseSeconds,
                    customLoopDurationSeconds: customLoopDuration,
                    user: user,
                    sets: sets,
                    reps: reps,
                    expertPauseSeconds: expertPauseSeconds,
                    mobilitySets: mobilitySets,
                                   mobilityReps: mobilityReps,
                                   mobilityPauseSeconds: mobilityPauseSeconds,
                    recurrenceRule: .weekly,
                    recurrenceGroupID: groupId
                )
                schedule.isAutoGenerated = true
                schedule.dayOfWeek = dayIndex
                schedule.planMode = "weekly"
                schedule.weightKg = weightKg
                try repository.save(schedule)
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
    }
}

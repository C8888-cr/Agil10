//
//  AddScheduleUseCase.swift
//  Agil10.0
//

import Foundation

@MainActor
final class AddScheduleUseCase {
    private let repository: VideoScheduleRepositoryProtocol

    init(repository: VideoScheduleRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        video: Video,
        date: Date,
        user: User,
        planMode: String? = nil,
        startTime: Date = Date(),
        customRepetitions: Int? = nil,
        customPauseSeconds: Int? = nil,
        customLoopDuration: Int? = nil,
        sets: Int? = nil,
        reps: Int? = nil,
        expertPauseSeconds: Int? = nil,
        mobilitySets: Int? = nil,
                mobilityReps: Int? = nil,
                mobilityPauseSeconds: Int? = nil,
        mobilityWeightKg: Int? = nil,
        weightKg: Int? = nil,
        notes: String? = nil
    ) throws {
        guard let videoInContext = try repository.fetchVideo(by: video.id) else {
            throw ScheduleError.videoNotFound
        }
        guard let userInContext = try repository.fetchUser(by: user.id) else {
            throw ScheduleError.userNotFound
        }

        let existing = try repository.fetchSchedules(for: date, userId: user.id)
        let nextIndex = existing.count

        let schedule = VideoSchedule(
            scheduledDate: Calendar.current.startOfDay(for: date),
            startTime: startTime,
            orderIndex: nextIndex,
            video: videoInContext,
            customRepetitions: customRepetitions,
            customPauseSeconds: customPauseSeconds,
            customLoopDurationSeconds: customLoopDuration,
            user: userInContext,
            sets: sets,
            reps: reps,
            expertPauseSeconds: expertPauseSeconds,
            mobilitySets: mobilitySets,
                       mobilityReps: mobilityReps,
                       mobilityPauseSeconds: mobilityPauseSeconds,
            mobilityWeightKg: mobilityWeightKg
            
        )
        schedule.notes = notes
        schedule.weightKg = weightKg

        if let planMode {
            schedule.planMode = planMode
        } else {
            let preferences = try repository.fetchUserPreferences(for: user.id)
            schedule.planMode = preferences?.activeMode ?? "single"
        }

        try repository.save(schedule)
    }
}

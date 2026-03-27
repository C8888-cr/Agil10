//
//  VideoScheduleRepository.swift
//  Agil10.0
//
//  Created by Christiane Roth on 23.03.26.
//


// Features/Schedule/Data/VideoScheduleRepository.swift
import Foundation
import SwiftData

@MainActor
class VideoScheduleRepository: VideoScheduleRepositoryProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch für ein Datum
    func fetchSchedules(for date: Date, userId: UUID) throws -> [VideoSchedule] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let descriptor = FetchDescriptor<VideoSchedule>(
            predicate: #Predicate { schedule in
                schedule.scheduledDate >= startOfDay &&
                schedule.scheduledDate < endOfDay &&
                schedule.isTemplate == false
            },
            sortBy: [SortDescriptor(\.orderIndex)]
        )

        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.user?.id == userId }
    }

    // MARK: - Fetch für Zeitraum
    func fetchSchedules(from startDate: Date, to endDate: Date, userId: UUID) throws -> [VideoSchedule] {
        let descriptor = FetchDescriptor<VideoSchedule>(
            predicate: #Predicate { schedule in
                schedule.scheduledDate >= startDate &&
                schedule.scheduledDate < endDate &&
                schedule.isTemplate == false
            },
            sortBy: [SortDescriptor(\.scheduledDate)]
        )

        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.user?.id == userId }
    }

    // MARK: - Fetch alle
    func fetchAllSchedules(userId: UUID) throws -> [VideoSchedule] {
        let descriptor = FetchDescriptor<VideoSchedule>(
            sortBy: [SortDescriptor(\.scheduledDate)]
        )

        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.user?.id == userId }
    }

    // MARK: - Save / Delete
    func save(_ schedule: VideoSchedule) throws {
        modelContext.insert(schedule)
        try modelContext.save()
    }

    func delete(_ schedule: VideoSchedule) throws {
        modelContext.delete(schedule)
        try modelContext.save()
    }

    func saveChanges() throws {
        try modelContext.save()
    }
    
    func fetchVideo(by id: UUID) throws -> Video? {
        let descriptor = FetchDescriptor<Video>(
            predicate: #Predicate<Video> { v in
                v.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchUser(by id: UUID) throws -> User? {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchUserPreferences(for userId: UUID) throws -> UserPreferences? {
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate<UserPreferences> { prefs in
                prefs.userId == userId
            }
        )
        return try modelContext.fetch(descriptor).first
    }
}

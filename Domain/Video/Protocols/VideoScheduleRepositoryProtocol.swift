//
//  VideoScheduleRepositoryProtocol.swift
//  Agil10.0
//
//  Created by Christiane Roth on 23.03.26.
//


// Features/Schedule/Data/VideoScheduleRepositoryProtocol.swift
import Foundation

@MainActor
protocol VideoScheduleRepositoryProtocol {
    func fetchSchedules(for date: Date, userId: UUID) throws -> [VideoSchedule]
    func fetchSchedules(from startDate: Date, to endDate: Date, userId: UUID) throws -> [VideoSchedule]
    func fetchAllSchedules(userId: UUID) throws -> [VideoSchedule]
    func save(_ schedule: VideoSchedule) throws
    func delete(_ schedule: VideoSchedule) throws
    func saveChanges() throws
    
    func fetchVideo(by id: UUID) throws -> Video?
    func fetchUser(by id: UUID) throws -> User?
    func fetchUserPreferences(for userId: UUID) throws -> UserPreferences?
    func fetchTemplates(for userId: UUID, isWeekly: Bool) throws -> [VideoSchedule]
    func fetchAutoSchedules(from date: Date, dayOfWeek: Int, userId: UUID) throws -> [VideoSchedule]
}

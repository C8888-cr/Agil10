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
}
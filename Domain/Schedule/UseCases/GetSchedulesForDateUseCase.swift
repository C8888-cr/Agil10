//
//  GetSchedulesForDateUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import Foundation

@MainActor
final class GetSchedulesForDateUseCase {
    private let repository: VideoScheduleRepositoryProtocol

    init(repository: VideoScheduleRepositoryProtocol) {
        self.repository = repository
    }

    func execute(date: Date, userId: UUID) throws -> [VideoSchedule] {
        
        let all = try repository.fetchSchedules(for: date, userId: userId)
        let preferences = try repository.fetchUserPreferences(for: userId)
        let activeMode = preferences?.activeMode ?? "single"
        print("🔍 activeMode beim Laden: \(activeMode), date: \(date)")
        print("🔍 GetSchedules: activeMode=\(activeMode), all=\(all.count), filtered=\(all.filter { $0.planMode == activeMode }.count)")
        for s in all { print("   - \(s.video?.title ?? "?") planMode=\(s.planMode)") }
        return all.filter { $0.planMode == activeMode }
    }
}

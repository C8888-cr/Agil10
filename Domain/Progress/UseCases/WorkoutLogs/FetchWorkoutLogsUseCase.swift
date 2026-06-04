
//
//  FetchWorkoutLogsUseCase.swift
//  Agil
//
//  Liest Workout-Logs aus dem Repository.
//  Bewusst dünn: Filtern/Aggregieren passiert im MetricAggregator,
//  damit der UseCase nur "lesen" macht und der Aggregator wiederverwendbar bleibt.
//

import Foundation

@MainActor
final class FetchWorkoutLogsUseCase {
    private let repository: WorkoutLogRepositoryProtocol

    init(repository: WorkoutLogRepositoryProtocol) {
        self.repository = repository
    }

    func executeAll(for userId: UUID) throws -> [WorkoutLog] {
        try repository.fetchAll(userId: userId)
    }

    func execute(from start: Date, to end: Date, userId: UUID) throws -> [WorkoutLog] {
        try repository.fetch(from: start, to: end, userId: userId)
    }

    func execute(videoId: UUID, userId: UUID) throws -> [WorkoutLog] {
        try repository.fetchByVideo(videoId: videoId, userId: userId)
    }
}

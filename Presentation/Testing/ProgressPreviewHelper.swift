//
//  ProgressPreviewHelper.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//


// Presentation/Testing/ProgressPreviewHelper.swift
import SwiftData

@MainActor
struct ProgressPreviewHelper {
    static func makeProgressVM(context: ModelContext) -> ProgressViewModel {
        let repository = VideoScheduleRepository(modelContext: context)
        let sessionManager = SessionManager(
            userRepository: UserRepository(modelContext: context)
        )
        return ProgressViewModel(
            session: sessionManager,
            getSchedulesUseCase: GetSchedulesForDateUseCase(repository: repository),
            addScheduleUseCase: AddScheduleUseCase(repository: repository),
            removeScheduleUseCase: RemoveScheduleUseCase(repository: repository),
            toggleCompletionUseCase: ToggleScheduleCompletionUseCase(repository: repository),
            reorderSchedulesUseCase: ReorderSchedulesUseCase(repository: repository),
            dailyProgressUseCase: CalculateDailyProgressUseCase(repository: repository),
            weeklyProgressUseCase: CalculateWeeklyProgressUseCase(repository: repository),
            lifetimeProgressUseCase: CalculateLifetimeProgressUseCase(repository: repository)
        )
    }
}
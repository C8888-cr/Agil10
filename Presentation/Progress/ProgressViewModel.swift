
import SwiftUI
import Combine

@MainActor
final class ProgressViewModel: ObservableObject {

    // MARK: - Published UI State
    @Published var todaysSchedules: [VideoSchedule] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedDate: Date = Date()

    // Daily
    @Published var targetMinutes: Int = 0
    @Published var totalScheduledMinutes: Int = 0
    @Published var completedMinutes: Int = 0
    @Published var remainingMinutes: Int = 0
    @Published var remainingSeconds: Int = 0
    @Published var completedSeconds: Int = 0
    @Published var totalScheduledSeconds: Int = 0
    @Published var progressPercentage: Double = 0.0
    @Published var dailyProgress: Double = 0.0
    @Published var canAddMoreVideos: Bool = true

    // Weekly
    @Published var weeklyProgress: Double = 0.0
    @Published var weeklyCompletedMinutes: Int = 0
    @Published var weeklyTargetMinutes: Int = 0

    // Lifetime
    @Published var lifetimeProgress: Double = 0.0
    @Published var lifetimeCompletedMinutes: Int = 0
    @Published var lifetimeCompletedWorkouts: Int = 0
    @Published var lifetimeStreak: Int = 0

    // Video Progress Tracking
    @Published var videoProgressMap: [String: Double] = [:]

    var selectedDayIndex: Int {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let rawWeekday = calendar.component(.weekday, from: selectedDate)
        return (rawWeekday - firstWeekday + 7) % 7
    }

    // MARK: - Dependencies
    private let session: SessionManager
    private let getSchedulesUseCase: GetSchedulesForDateUseCase
    private let addScheduleUseCase: AddScheduleUseCase
    private let removeScheduleUseCase: RemoveScheduleUseCase
    private let toggleCompletionUseCase: ToggleScheduleCompletionUseCase
    private let reorderSchedulesUseCase: ReorderSchedulesUseCase
    private let dailyProgressUseCase: CalculateDailyProgressUseCase
    private let weeklyProgressUseCase: CalculateWeeklyProgressUseCase
    private let lifetimeProgressUseCase: CalculateLifetimeProgressUseCase

    private var cancellables = Set<AnyCancellable>()
    private var debounceSubject = PassthroughSubject<Void, Never>()
    private let addVideoToPlanUseCase: AddVideoToPlanUseCase
    // MARK: - Init
    init(
        session: SessionManager,
        getSchedulesUseCase: GetSchedulesForDateUseCase,
        addVideoToPlanUseCase: AddVideoToPlanUseCase,
        addScheduleUseCase: AddScheduleUseCase,
        removeScheduleUseCase: RemoveScheduleUseCase,
        toggleCompletionUseCase: ToggleScheduleCompletionUseCase,
        reorderSchedulesUseCase: ReorderSchedulesUseCase,
        dailyProgressUseCase: CalculateDailyProgressUseCase,
        weeklyProgressUseCase: CalculateWeeklyProgressUseCase,
        lifetimeProgressUseCase: CalculateLifetimeProgressUseCase
    ) {
        self.session = session
        self.getSchedulesUseCase = getSchedulesUseCase
        self.addVideoToPlanUseCase = addVideoToPlanUseCase
        self.addScheduleUseCase = addScheduleUseCase
        self.removeScheduleUseCase = removeScheduleUseCase
        self.toggleCompletionUseCase = toggleCompletionUseCase
        self.reorderSchedulesUseCase = reorderSchedulesUseCase
        self.dailyProgressUseCase = dailyProgressUseCase
        self.weeklyProgressUseCase = weeklyProgressUseCase
        self.lifetimeProgressUseCase = lifetimeProgressUseCase

        setupPreferencesObserver()
    }

    // MARK: - Load
    func loadHome(for user: User) {
        selectedDate = Date()
        loadToday(for: user, date: Date())
    }

    func loadToday(for user: User, date: Date? = nil) {
        let targetDate = date ?? Date()
        selectedDate = targetDate
        isLoading = true
        print("🔄 loadToday für: \(targetDate)")

        do {
            todaysSchedules = try getSchedulesUseCase.execute(date: targetDate, userId: user.id)
            print("📋 Schedules geladen: \(todaysSchedules.count)")
            calculateProgress(for: user)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func schedulesFor(date: Date) -> [VideoSchedule] {
        guard let user = session.currentUser else { return [] }
        return (try? getSchedulesUseCase.execute(date: date, userId: user.id)) ?? []
    }

    // MARK: - CRUD
    func addVideo(
        _ video: Video,
        to date: Date,
        for user: User,
        planMode: String? = nil,
        startTime: Date = Date(),
        customRepetitions: Int? = nil,
        customPauseSeconds: Int? = nil,
        customLoopDuration: Int? = nil,
        sets: Int? = nil,
        reps: Int? = nil,
        weightKg: Int? = nil,
        notes: String? = nil
    ) {
        do {
            let resolvedPlanMode = planMode ?? "single"

            if resolvedPlanMode != "single" {
                let calendar = Calendar.current
                let weekday = calendar.component(.weekday, from: date)
                let dayIndex = weekday == 1 ? 6 : weekday - 2
                try addVideoToPlanUseCase.execute(
                    video: video,
                    date: date,
                    user: user,
                    planMode: resolvedPlanMode,
                   
                    dayIndex: dayIndex,
                    customRepetitions: customRepetitions,
                    customPauseSeconds: customPauseSeconds,
                    customLoopDuration: customLoopDuration,
                    weightKg: weightKg
                )
          
            } else {
                try addScheduleUseCase.execute(
                    video: video,
                    date: date,
                    user: user,
                    planMode: resolvedPlanMode,
                    startTime: startTime,
                    customRepetitions: customRepetitions,
                    customPauseSeconds: customPauseSeconds,
                    customLoopDuration: customLoopDuration,
                    sets: sets,
                    reps: reps,
                    weightKg: weightKg, 
                    notes: notes
                )
            }

            if Calendar.current.isDate(date, inSameDayAs: selectedDate) {
                loadToday(for: user, date: date)
            }
        } catch {
            self.error = error
        }
    }
    
    
    func removeSchedule(_ schedule: VideoSchedule, for user: User) {
        do {
            try removeScheduleUseCase.execute(schedule, userId: user.id)
            if Calendar.current.isDate(schedule.scheduledDate, inSameDayAs: selectedDate) {
                loadToday(for: user, date: schedule.scheduledDate)
            }
        } catch {
            self.error = error
        }
    }

    func toggleCompletion(_ schedule: VideoSchedule, for user: User) {
        do {
            try toggleCompletionUseCase.toggle(schedule)
            calculateProgress(for: user)
        } catch {
            self.error = error
        }
    }

    func markCompletedSchedule(_ schedule: VideoSchedule, rating: Int? = nil, for user: User) {
        do {
            try toggleCompletionUseCase.markCompleted(schedule, rating: rating)
            calculateProgress(for: user)
        } catch {
            self.error = error
        }
    }

    func markIncompleteSchedule(_ schedule: VideoSchedule, for user: User) {
        do {
            try toggleCompletionUseCase.markIncomplete(schedule)
            calculateProgress(for: user)
        } catch {
            self.error = error
        }
    }

    func reorderSchedules(from source: IndexSet, to destination: Int, for user: User) {
        do {
            try reorderSchedulesUseCase.execute(
                schedules: &todaysSchedules,
                from: source,
                to: destination
            )
        } catch {
            self.error = error
        }
    }

    func updateSchedule(_ schedule: VideoSchedule, for user: User) {
        do {
            try toggleCompletionUseCase.saveChanges()
            calculateProgress(for: user)
        } catch {
            self.error = error
        }
    }

    // MARK: - Progress
    func calculateProgress(for user: User) {
        calculateDailyProgress(for: user, on: selectedDate)
    }

    func calculateDailyProgress(for user: User, on date: Date) {
        do {
            let result = try dailyProgressUseCase.execute(for: user, on: date)
            todaysSchedules = result.schedules
            targetMinutes = result.targetMinutes
            totalScheduledMinutes = result.totalScheduledMinutes
            completedMinutes = result.completedMinutes
            remainingMinutes = result.remainingMinutes
            remainingSeconds = result.remainingSeconds
            completedSeconds = result.completedSeconds
            totalScheduledSeconds = result.totalScheduledSeconds
            progressPercentage = result.progressPercentage
            dailyProgress = result.dailyProgress
            canAddMoreVideos = result.canAddMoreVideos
        } catch {
            self.error = error
        }
    }

    func calculateWeeklyProgress(for user: User) {
        do {
            let result = try weeklyProgressUseCase.execute(for: user)
            weeklyProgress = result.weeklyProgress
            weeklyCompletedMinutes = result.completedMinutes
            weeklyTargetMinutes = result.targetMinutes
        } catch {
            self.error = error
        }
    }

    func calculateLifetimeProgress(for user: User) {
        do {
            let result = try lifetimeProgressUseCase.execute(for: user)
            lifetimeProgress = result.lifetimeProgress
            lifetimeCompletedMinutes = result.completedMinutes
            lifetimeCompletedWorkouts = result.completedWorkouts
            lifetimeStreak = result.streak
        } catch {
            self.error = error
        }
    }

    func calculateAllProgress(for user: User) {
        calculateDailyProgress(for: user, on: selectedDate)
        calculateWeeklyProgress(for: user)
        calculateLifetimeProgress(for: user)
    }

    // MARK: - Video Progress Tracking
    func updateVideoProgress(for videoId: String, progress: Double) {
        videoProgressMap[videoId] = min(1.0, max(0.0, progress))
    }

    func getVideoProgress(for videoId: String) -> Double {
        videoProgressMap[videoId] ?? 0.0
    }

    func resetVideoProgress(for videoId: String) {
        videoProgressMap.removeValue(forKey: videoId)
    }

    // MARK: - Helpers
    func formattedTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes) Min"
    }

    // MARK: - Preferences Observer
    private func setupPreferencesObserver() {
        debounceSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let user = session.currentUser else { return }
                let calendar = Calendar.current
                let todayStart = calendar.startOfDay(for: Date())
                let selectedStart = calendar.startOfDay(for: selectedDate)
                if selectedStart == todayStart {
                    loadHome(for: user)
                } else {
                    loadToday(for: user, date: selectedDate)
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .preferencesDidChange)
            .sink { [weak self] _ in self?.debounceSubject.send() }
            .store(in: &cancellables)
    }
}
extension ProgressViewModel {
    
    func moveSchedule(_ source: VideoSchedule, before target: VideoSchedule, for user: User) {
        guard let sourceIndex = todaysSchedules.firstIndex(where: { $0.id == source.id }),
              var destinationIndex = todaysSchedules.firstIndex(where: { $0.id == target.id })
        else { return }
        
        if sourceIndex < destinationIndex {
            destinationIndex += 1
        }
        
        reorderSchedules(
            from: IndexSet(integer: sourceIndex),
            to: destinationIndex,
            for: user
        )
    }
    
    func moveSchedule(_ source: VideoSchedule, after target: VideoSchedule, for user: User) {
        guard let sourceIndex = todaysSchedules.firstIndex(where: { $0.id == source.id }),
              let targetIndex = todaysSchedules.firstIndex(where: { $0.id == target.id })
        else { return }
        
        // "after" heißt: an Position targetIndex + 1
        let destinationIndex = targetIndex + 1
        
        // Nichts zu tun, wenn Source schon direkt danach ist
        if sourceIndex == destinationIndex { return }
        
        reorderSchedules(
            from: IndexSet(integer: sourceIndex),
            to: destinationIndex,
            for: user
        )
    }
}

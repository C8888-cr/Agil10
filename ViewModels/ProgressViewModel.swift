

import SwiftUI
import SwiftData
import Combine
@MainActor
class ProgressViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var targetMinutes: Int = 0
    @Published var todaysSchedules: [VideoSchedule] = []
    @Published var isLoading = false
    @Published var error: Error?

    
    // Progress
    @Published var totalScheduledMinutes: Int = 0
    @Published var completedMinutes: Int = 0
    @Published var remainingMinutes: Int = 0
    @Published var progressPercentage: Double = 0.0
    @Published var dailyProgress: Double = 0.0  // 0.0 ... 1.0 für Progress Ring
    // Weekly Progress
    @Published var weeklyProgress: Double = 0.0
    @Published var weeklyCompletedMinutes: Int = 0
    @Published var weeklyTargetMinutes: Int = 0
    // Lifetime Progress
    @Published var lifetimeProgress: Double = 0.0
    @Published var lifetimeCompletedMinutes: Int = 0
    @Published var lifetimeCompletedWorkouts: Int = 0
    @Published var lifetimeStreak: Int = 0

    
    // ✅ NEU: Video Watch Progress
    @Published var videoProgressMap: [String: Double] = [:]
       
    @Published var selectedDate: Date = Date()  // ✅ Default = heute
    // ✅ Computed Property für selected day index
    var selectedDayIndex: Int {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let rawWeekday = calendar.component(.weekday, from: selectedDate)  // ✅
        return (rawWeekday - firstWeekday + 7) % 7
    }
    
    // State
    @Published var canAddMoreVideos: Bool = true
    @Published var showAddVideoSheet = false
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext

    private let calendar = Calendar.current
    
    // ✅ NEU: Combine für Debounce
      private var cancellables = Set<AnyCancellable>()
      private var debounceSubject = PassthroughSubject<Void, Never>()

    
    // ✅ AuthService aus AppDependencies holen
      var authService: AuthService {
           AppDependencies.shared.authService
       }
       
       // ✅ Dann currentUser daraus holen
       var currentUser: User? {
           authService.currentUser
       }
    

    
    // MARK: - Init
    
    init(modelContext: ModelContext) {
           self.modelContext = modelContext
      
           loadTodaysSchedules()
       
        // ✅ Setup Notification Listener
        setupPreferencesObserver()
    }
    // ✅ Eigene Funktion (ist automatisch @MainActor weil class ist @MainActor)
    private func setupPreferencesObserver() {
        debounceSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let user = self.currentUser else {
                    print("⚠️ [DEBOUNCED] Kein User - skip reload")
                    return
                }
                
                print("🔔 [DEBOUNCED] Preferences changed - reloading TODAY...")
                self.loadToday(for: user)  // ✅ Das ist der Fix!
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .preferencesDidChange)
            .sink { [weak self] _ in
                print("📨 Notification received (queuing for debounce)")
                self?.debounceSubject.send()
            }
            .store(in: &cancellables)
    }
    
    /// Videos für beliebiges Datum holen
       func schedulesFor(date: Date) -> [VideoSchedule] {
           let startOfDay = Calendar.current.startOfDay(for: date)
           let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
           
           let descriptor = FetchDescriptor<VideoSchedule>(
               predicate: #Predicate { schedule in
                   schedule.scheduledDate >= startOfDay &&
                   schedule.scheduledDate < endOfDay
               },
               sortBy: [SortDescriptor(\.orderIndex), SortDescriptor(\.startTime)]
           )
           
           return (try? modelContext.fetch(descriptor)) ?? []
       }
    // MARK: - Load Today's Data
    /// Heute laden
      func loadTodaysSchedules() {
          todaysSchedules = schedulesFor(date: Date())
      }
    
    func loadToday(for user: User, date: Date? = nil) {
        if let date = date {
               selectedDate = date  // ✅ Setze ausgewähltes Datum
           }
        isLoading = true
        
        do {
            let today = calendar.startOfDay(for: selectedDate)
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
                isLoading = false
                return
            }
            
            let userId = user.id
            print("🔍 Looking for schedules for userId: \(userId)")
            print("📅 Target Date: \(today)")
            
            
            let descriptor = FetchDescriptor<VideoSchedule>(
                predicate: #Predicate<VideoSchedule> { schedule in
                    schedule.scheduledDate >= today &&
                    schedule.scheduledDate < tomorrow
                },
                sortBy: [SortDescriptor(\.orderIndex)]
            )
            
            let allSchedules = try modelContext.fetch(descriptor)
            todaysSchedules = allSchedules.filter { $0.user?.id == userId }
            print("🔍 After filter: \(todaysSchedules.count) schedules for THIS user")
            
            // Debug: Print all users in the schedules
                   for schedule in allSchedules {
                       if let scheduleUserId = schedule.user?.id {
                                       print("   - Schedule userId: \(scheduleUserId) vs our userId: \(userId) → Match: \(scheduleUserId == userId)")
                                   } else {
                                       print("   - Schedule has NO USER")
                                   }
                               }
            
            // ✅ HINZUFÜGEN:
               calculateProgress(for: user)  // ← Progress + dailyProgress updaten!
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
  /*
    // ✅ 1. Die NEUE Methode MIT date Parameter (die echte Logik)
    private func _calculateProgress(for user: User, on date: Date) {
        let date = selectedDate
        print("🔄 Progress wird neu berechnet...")
        print("   Current User: \(user.email)")
        print("   User ID: \(user.id)")
        print("   Target Date: \(date)")  // ✅ Nutze den Parameter!
        print("   ModelContext: \(ObjectIdentifier(modelContext))")
        
        let userId = user.id
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        guard let userInContext = try? modelContext.fetch(userDescriptor).first else {
            print("❌ User nicht im Context!")
            dailyProgress = 0.0
            return
        }
        
        print("🔍 Checking user.preferences...")
        print("   user.preferences: \(userInContext.preferences != nil ? "EXISTS" : "NIL")")
        
        guard let preferences = userInContext.preferences else {
            print("⚠️ No preferences found for user")
            let completedSchedules = todaysSchedules.filter { $0.isCompleted }
            dailyProgress = Double(completedSchedules.count) / Double(max(1, todaysSchedules.count))
            print("🎯 dailyProgress (no prefs): \(Int(dailyProgress * 100))%")
            return
        }
        
        print("✅ Preferences gefunden:")
        print("   - Preferences ID: \(preferences.id)")
        print("   - Goals count: \(preferences.weeklyGoals.count)")
        
        // ✅ DURCH date Parameter ersetzen:
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let rawWeekday = calendar.component(.weekday, from: date)  // ← date Parameter!
        let todayDayOfWeek = (rawWeekday - firstWeekday + 7) % 7
        
        print("📅 Day Index for date: \(todayDayOfWeek)")
        
        guard let todayGoal = preferences.getGoalFor(dayOfWeek: todayDayOfWeek) else {
            print("⚠️ No goal for day \(todayDayOfWeek)")
            return
        }
        
        let targetMinutes = todayGoal.targetMinutes
        self.targetMinutes = targetMinutes
        let interVideoPause = todayGoal.interVideoPauseSeconds
        
        var totalSeconds = 0
        for (index, schedule) in todaysSchedules.enumerated() {
            totalSeconds += schedule.totalDurationSeconds
            if index < todaysSchedules.count - 1 {
                totalSeconds += interVideoPause
            }
        }
        
        totalScheduledMinutes = totalSeconds / 60
        
        let completedSchedules = todaysSchedules.filter { $0.isCompleted }
        var completedSeconds = 0
        for (index, schedule) in completedSchedules.enumerated() {
            completedSeconds += schedule.totalDurationSeconds
            if index < completedSchedules.count - 1 {
                completedSeconds += interVideoPause
            }
        }
        
        completedMinutes = completedSeconds / 60
        remainingMinutes = max(0, targetMinutes - totalScheduledMinutes)
        progressPercentage = targetMinutes > 0 ?
            Double(totalScheduledMinutes) / Double(targetMinutes) : 0.0
        
        dailyProgress = completedMinutes > 0 && targetMinutes > 0 ?
            Double(completedMinutes) / Double(targetMinutes) : 0.0
        
        print("🎯 dailyProgress aktualisiert!")
        print("   Completed Minutes: \(completedMinutes)")
        print("   Target Minutes: \(targetMinutes)")
        print("   Progress: \(Int(dailyProgress * 100))%")
        
        canAddMoreVideos = remainingMinutes > 0
    }
    // PUBLIC
    func calculateProgress(for user: User) {
        _calculateProgress(for: user, on: selectedDate)
    }
    func calculateProgress(for user: User, on date: Date) {
        selectedDate = date  // ✅ Setze erst selectedDate
        _calculateProgress(for: user, on: selectedDate)  // ✅ Dann rechnen
    }
   
   */
  
    // MARK: - Add Video
    /// Video zu bestimmtem Datum hinzufügen
    func addVideo(
        _ video: Video,
        to date: Date,
        for user: User,
        startTime: Date = Date(),
        customRepetitions: Int? = nil,
        customPauseSeconds: Int? = nil,
        customLoopDuration: Int? = nil,
        sets: Int? = nil,
        reps: Int? = nil,
        notes: String? = nil
    ) {
        print("🔍 addVideo START")
        print("   📹 Video: \(video.title) (ID: \(video.id))")
        print("   📅 Date: \(date)")
        print("   👤 User: \(user.email) (ID: \(user.id))")
        
        // ✅ 1. UUIDs in lokale Variablen
        let videoId = video.id
        let userId = user.id
        
        // ✅ 2. Video im Context holen
        let videoDescriptor = FetchDescriptor<Video>(
            predicate: #Predicate<Video> { v in
                v.id == videoId
            }
        )
        
        guard let videoInContext = try? modelContext.fetch(videoDescriptor).first else {
            print("❌ Video nicht im Context!")
            return
        }
        print("✅ Video found in context")
        
        // ✅ 3. User im Context holen
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        guard let userInContext = try? modelContext.fetch(userDescriptor).first else {
            print("❌ User nicht im Context!")
            return
        }
        print("✅ User found in context")
        
        // ✅ 4. Nächsten Index für DIESES Datum berechnen
        let existingSchedules = schedulesFor(date: date)
        let nextIndex = existingSchedules.count
        
        // ✅ 5. Schedule erstellen
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
            reps: reps
        )
        
        schedule.notes = notes
        
        print("📦 Schedule erstellt: Index \(nextIndex)")
        
        modelContext.insert(schedule)
        print("✅ Schedule inserted in context")
        
        do {
            try modelContext.save()
            print("✅ ✅ ✅ SCHEDULE SAVED!")
            
            // ✅ Nur neu laden wenn für selectedDate
            if Calendar.current.isDate(date, inSameDayAs: selectedDate) {
                loadToday(for: userInContext, date: date)
            }
            
        } catch {
            print("❌ ❌ ❌ SAVE FAILED!")
            print("   Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    
    func canAddVideo(_ video: Video, for user: User) -> Bool {
        guard let preferences = fetchUserPreferences(for: user) else { return false }
        
        let todayDayOfWeek = Calendar.current.component(.weekday, from: Date()) - 1
        guard let todayGoal = preferences.getGoalFor(dayOfWeek: todayDayOfWeek) else {
            return false
        }
        
        let currentMinutes = todaysSchedules
            .reduce(0) { $0 + $1.totalDurationMinutes }
        
        let newVideoMinutes = video.durationSeconds / 60
        
        return currentMinutes + newVideoMinutes <= todayGoal.targetMinutes
    }
        
        
    private func fetchUserPreferences(for user: User) -> UserPreferences? {
        let userId = user.id
        
        let descriptor = FetchDescriptor<UserPreferences>(
                predicate: #Predicate<UserPreferences> { prefs in
                    prefs.userId == userId
                }
            )
        
        
        guard let allPreferences = try? modelContext.fetch(descriptor) else { return nil }
        return allPreferences.first
    }
    
  
    // MARK: - Remove Video
    /// Video-Schedule entfernen und Indizes neu ordnen
    func removeSchedule(_ schedule: VideoSchedule, for user: User) {
        let scheduleDate = schedule.scheduledDate  // ✅ Datum merken!
        
        modelContext.delete(schedule)
        
        // ✅ Nur Schedules vom GLEICHEN Datum neu ordnen
        let remainingSchedules = schedulesFor(date: scheduleDate)
            .sorted { $0.orderIndex < $1.orderIndex }
        
        for (index, remainingSchedule) in remainingSchedules.enumerated() {
            remainingSchedule.orderIndex = index
        }
        
        do {
            try modelContext.save()
            
            // ✅ Nur neu laden wenn es das selectedDate betrifft
            if Calendar.current.isDate(scheduleDate, inSameDayAs: selectedDate) {
                loadToday(for: user, date: scheduleDate)
            }
            
        } catch {
            print("❌ removeSchedule Error: \(error)")
            self.error = error
        }
    }
    
    // MARK: - Toggle Completion
    
    func toggleCompletion(_ schedule: VideoSchedule, for user: User) {
        schedule.isCompleted.toggle()
        
        if schedule.isCompleted {
            schedule.completedAt = Date()
        } else {
            schedule.completedAt = nil
            schedule.rating = nil
        }
        
        do {
            try modelContext.save()
            calculateProgress(for: user)  // ✅ Das update auch dailyProgress!
            print("✅ Schedule \(schedule.isCompleted ? "completed" : "uncompleted")")
        } catch {
            print("❌ toggleCompletion Error: \(error)")
            self.error = error
        }
    }
    /// Schedule als erledigt markieren (mit optionalem Rating)
    func markCompletedSchedule(_ schedule: VideoSchedule, rating: Int? = nil, for user: User) {
        schedule.isCompleted = true
        schedule.completedAt = Date()
        schedule.rating = rating
        
        do {
            try modelContext.save()
            calculateProgress(for: user)
            print("✅ Schedule marked completed (Rating: \(rating ?? 0))")
        } catch {
            print("❌ markCompleted Error: \(error)")
            self.error = error
        }
    }
    /// Erledigung rückgängig machen
    func markIncompleteSchedule(_ schedule: VideoSchedule, for user: User) {
        schedule.isCompleted = false
        schedule.completedAt = nil
        schedule.rating = nil
        
        do {
            try modelContext.save()
            calculateProgress(for: user)
            print("✅ Schedule marked incomplete")
        } catch {
            print("❌ markIncomplete Error: \(error)")
            self.error = error
        }
    }
    // MARK: - Reorder
    
    func reorderSchedules(from source: IndexSet, to destination: Int, for user: User) {
        var reordered = todaysSchedules
        reordered.move(fromOffsets: source, toOffset: destination)
        
        for (index, schedule) in reordered.enumerated() {
            schedule.orderIndex = index
        }
        
        do {
            try modelContext.save()
            loadToday(for: user)
        } catch {
            self.error = error
        }
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
    
    // MARK: - Update Schedule
    
    func updateSchedule(_ schedule: VideoSchedule, for user: User) {
 
        do {
            try modelContext.save()
            calculateProgress(for: user)
            print("✅ Schedule updated")
        } catch {
            print("❌ Error: \(error)")
        }
    }


    
    // MARK: - Video Progress Tracking ✅ NEU
       
       func updateVideoProgress(for videoId: String, progress: Double) {
           videoProgressMap[videoId] = min(1.0, max(0.0, progress))
       }
       
       func getVideoProgress(for videoId: String) -> Double {
           return videoProgressMap[videoId] ?? 0.0
       }
       
       func resetVideoProgress(for videoId: String) {
           videoProgressMap.removeValue(forKey: videoId)
       }
    
  
    // MARK: - Progress Calculation
    
    // 📅 1. DAILY PROGRESS - für ein bestimmtes Datum
    func calculateDailyProgress(for user: User, on date: Date) {
        print("🔄 Daily Progress für \(date)...")
        
        let userId = user.id
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        guard let userInContext = try? modelContext.fetch(userDescriptor).first else {
            print("❌ User nicht im Context!")
            dailyProgress = 0.0
            return
        }
        
        guard let preferences = userInContext.preferences else {
            print("⚠️ No preferences")
            let completedSchedules = todaysSchedules.filter { $0.isCompleted }
            dailyProgress = Double(completedSchedules.count) / Double(max(1, todaysSchedules.count))
            return
        }
        
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let rawWeekday = calendar.component(.weekday, from: date)
        let todayDayOfWeek = (rawWeekday - firstWeekday + 7) % 7
        
        guard let todayGoal = preferences.getGoalFor(dayOfWeek: todayDayOfWeek) else {
            print("⚠️ No goal for day \(todayDayOfWeek)")
            return
        }
        
        let targetMinutes = todayGoal.targetMinutes
        self.targetMinutes = targetMinutes
        let interVideoPause = todayGoal.interVideoPauseSeconds
        
        var totalSeconds = 0
        for (index, schedule) in todaysSchedules.enumerated() {
            totalSeconds += schedule.totalDurationSeconds
            if index < todaysSchedules.count - 1 {
                totalSeconds += interVideoPause
            }
        }
        
        totalScheduledMinutes = totalSeconds / 60
        
        let completedSchedules = todaysSchedules.filter { $0.isCompleted }
        var completedSeconds = 0
        for (index, schedule) in completedSchedules.enumerated() {
            completedSeconds += schedule.totalDurationSeconds
            if index < completedSchedules.count - 1 {
                completedSeconds += interVideoPause
            }
        }
        
        completedMinutes = completedSeconds / 60
        remainingMinutes = max(0, targetMinutes - totalScheduledMinutes)
        progressPercentage = targetMinutes > 0 ?
            Double(totalScheduledMinutes) / Double(targetMinutes) : 0.0
        
        dailyProgress = completedMinutes > 0 && targetMinutes > 0 ?
            Double(completedMinutes) / Double(targetMinutes) : 0.0
        
        print("🎯 dailyProgress: \(Int(dailyProgress * 100))%")
        
        canAddMoreVideos = remainingMinutes > 0
    }
    
    // Convenience: Daily Progress für selectedDate
    func calculateProgress(for user: User) {
        calculateDailyProgress(for: user, on: selectedDate)
    }
    
    // 📊 2. WEEKLY PROGRESS - für aktuelle Woche
    func calculateWeeklyProgress(for user: User) {
        print("📊 Weekly Progress berechnen...")
        
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            print("❌ Konnte Wochenstart nicht berechnen")
            return
        }
        
        let userId = user.id
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        let descriptor = FetchDescriptor<VideoSchedule>(
            predicate: #Predicate<VideoSchedule> { schedule in
                schedule.scheduledDate >= weekStart &&
                schedule.scheduledDate < weekEnd
            }
        )
        
        guard let allSchedules = try? modelContext.fetch(descriptor) else {
            print("❌ Konnte Schedules nicht laden")
            return
        }
        
        let userSchedules = allSchedules.filter { $0.user?.id == userId }
        let completedSchedules = userSchedules.filter { $0.isCompleted }
        
        let completedMinutes = completedSchedules.reduce(0) { $0 + $1.totalDurationMinutes }
        
        guard let preferences = user.preferences else {
            print("⚠️ No preferences for weekly calculation")
            return
        }
        
        var weeklyTarget = 0
        for dayOfWeek in 0..<7 {
            if let goal = preferences.getGoalFor(dayOfWeek: dayOfWeek) {
                weeklyTarget += goal.targetMinutes
            }
        }
        
        self.weeklyCompletedMinutes = completedMinutes
        self.weeklyTargetMinutes = weeklyTarget
        self.weeklyProgress = weeklyTarget > 0 ?
            Double(completedMinutes) / Double(weeklyTarget) : 0.0
        
        print("📊 Weekly: \(completedMinutes)/\(weeklyTarget) Min (\(Int(weeklyProgress * 100))%)")
    }
    
    // 🌍 3. LIFETIME PROGRESS - alle Zeit
    func calculateLifetimeProgress(for user: User) {
        print("🌍 Lifetime Progress berechnen...")
        
        let userId = user.id
        
        let descriptor = FetchDescriptor<VideoSchedule>(
            sortBy: [SortDescriptor(\.scheduledDate)]
        )
        
        guard let allSchedules = try? modelContext.fetch(descriptor) else {
            print("❌ Konnte Schedules nicht laden")
            return
        }
        
        let userSchedules = allSchedules.filter { $0.user?.id == userId }
        let completedSchedules = userSchedules.filter { $0.isCompleted }
        
        let totalMinutes = completedSchedules.reduce(0) { $0 + $1.totalDurationMinutes }
        let totalWorkouts = completedSchedules.count
        let streak = calculateStreak(from: userSchedules)
        
        self.lifetimeCompletedMinutes = totalMinutes
        self.lifetimeCompletedWorkouts = totalWorkouts
        self.lifetimeStreak = streak
        
        // Lifetime Progress = % der Tage mit erreichtem Ziel
        let uniqueDates = Set(userSchedules.map { Calendar.current.startOfDay(for: $0.scheduledDate) })
        let daysWithGoalReached = uniqueDates.filter { date in
            let schedulesForDay = userSchedules.filter {
                Calendar.current.isDate($0.scheduledDate, inSameDayAs: date)
            }
            let completedForDay = schedulesForDay.filter { $0.isCompleted }
            
            guard let preferences = user.preferences else { return false }
            let calendar = Calendar.current
            let firstWeekday = calendar.firstWeekday
            let rawWeekday = calendar.component(.weekday, from: date)
            let dayOfWeek = (rawWeekday - firstWeekday + 7) % 7
            
            guard let goal = preferences.getGoalFor(dayOfWeek: dayOfWeek) else { return false }
            
            let completedMinutes = completedForDay.reduce(0) { $0 + $1.totalDurationMinutes }
            return completedMinutes >= goal.targetMinutes
        }
        
        self.lifetimeProgress = uniqueDates.count > 0 ?
            Double(daysWithGoalReached.count) / Double(uniqueDates.count) : 0.0
        
        print("🌍 Lifetime: \(totalMinutes) Min, \(totalWorkouts) Workouts, \(streak) Days Streak")
    }
    
    // Helper: Streak berechnen
    private func calculateStreak(from schedules: [VideoSchedule]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        let dateGroups = Dictionary(grouping: schedules) { schedule in
            calendar.startOfDay(for: schedule.scheduledDate)
        }
        
        let sortedDates = dateGroups.keys.sorted(by: >)
        
        guard let mostRecentDate = sortedDates.first else { return 0 }
        
        let daysSinceMostRecent = calendar.dateComponents([.day], from: mostRecentDate, to: now).day ?? 999
        if daysSinceMostRecent > 1 { return 0 }
        
        var streak = 0
        var checkDate = calendar.startOfDay(for: now)
        
        while true {
            if let schedulesForDay = dateGroups[checkDate],
               schedulesForDay.contains(where: { $0.isCompleted }) {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else {
                break
            }
        }
        
        return streak
    }
    
    // 🔄 4. ALL PROGRESS - alle auf einmal aktualisieren
    func calculateAllProgress(for user: User) {
        calculateDailyProgress(for: user, on: selectedDate)
        calculateWeeklyProgress(for: user)
        calculateLifetimeProgress(for: user)
    }
    
    
}
// In ProgressViewModel.swift
extension ProgressViewModel {
    
    /// Berechnet Gesamtdauer für einen Schedule (inkl. Pausen)
    func calculateTotalDuration(for schedule: VideoSchedule) -> String {
        let loopDuration = schedule.effectiveLoopDurationSeconds
        let repetitions = schedule.effectiveRepetitions
        let pauseSeconds = schedule.effectivePauseSeconds
        
        let totalSeconds = (loopDuration * repetitions) + max(0, (repetitions - 1) * pauseSeconds)
        
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return secs > 0 ? "\(minutes):\(String(format: "%02d", secs)) Min" : "\(minutes) Min"
    }
    func getTodaysTargetMinutes(from settingsVM: SettingsViewModel, for date: Date = Date()) -> Int {
         let calendar = Calendar.current
         let firstWeekday = calendar.firstWeekday
         let rawWeekday = calendar.component(.weekday, from: date)
         let todayDayOfWeek = (rawWeekday - firstWeekday + 7) % 7
         
         return settingsVM.preferences.getGoalFor(dayOfWeek: todayDayOfWeek)?.targetMinutes ?? 30
     }
    
}

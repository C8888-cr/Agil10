

import SwiftUI
import SwiftData
import Combine
@MainActor
class ProgressViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var todaysSchedules: [VideoSchedule] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // Progress
    @Published var totalScheduledMinutes: Int = 0
    @Published var completedMinutes: Int = 0
    @Published var remainingMinutes: Int = 0
    @Published var progressPercentage: Double = 0.0
    @Published var dailyProgress: Double = 0.0  // 0.0 ... 1.0 für Progress Ring

    
    // ✅ NEU: Video Watch Progress
       @Published var videoProgressMap: [String: Double] = [:]
       
    
    // State
    @Published var canAddMoreVideos: Bool = true
    @Published var showAddVideoSheet = false
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext

    private let calendar = Calendar.current

    
    // ✅ AuthService aus AppDependencies holen
       private var authService: AuthService {
           AppDependencies.shared.authService
       }
       
       // ✅ Dann currentUser daraus holen
       private var currentUser: User? {
           authService.currentUser
       }
    

    
    // MARK: - Init
    
    init(modelContext: ModelContext) {
           self.modelContext = modelContext
       }

    // MARK: - Load Today's Data
    
    func loadToday(for user: User) {

        isLoading = true
        
        do {
            let today = calendar.startOfDay(for: Date())
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
                isLoading = false
                return
            }
            
            let userId = user.id
            print("🔍 Looking for schedules for userId: \(userId)")
            
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
    
    // MARK: - Calculate Progress
    private func calculateProgress(for user: User) {
        print("🔄 Progress wird neu berechnet...")
        do {
         
            
            let preferenceDescriptor = FetchDescriptor<UserPreferences>()
            let allPreferences = try modelContext.fetch(preferenceDescriptor)
            
            guard let preferences = allPreferences.first else {
                print("⚠️ No preferences found for user")
              
                
                // ✅ Trotzdem dailyProgress berechnen!
                let completedSchedules = todaysSchedules.filter { $0.isCompleted }
                dailyProgress = Double(completedSchedules.count) / Double(max(1, todaysSchedules.count))
                print("🎯 dailyProgress (no prefs): \(Int(dailyProgress * 100))%")
                
                return
            }
            // ✅ HIER ÄNDERN: Ziel für HEUTE holen
            let calendar = Calendar.current
            let firstWeekday = calendar.firstWeekday
            let rawWeekday = calendar.component(.weekday, from: Date())
            let todayDayOfWeek = (rawWeekday - firstWeekday + 7) % 7
            
            
            print("📅 RAW: \(rawWeekday), first: \(firstWeekday), Index: \(todayDayOfWeek)")
            
            
                   guard let todayGoal = preferences.getGoalFor(dayOfWeek: todayDayOfWeek) else {
                       print("⚠️ No goal for today (day \(todayDayOfWeek))")
                              return                   }
                   
                   let targetMinutes = todayGoal.targetMinutes
                   let interVideoPause = todayGoal.interVideoPauseSeconds  // ✅ Auch von DayGoal
                   
                   // Calculate total scheduled time
                   var totalSeconds = 0
                   for (index, schedule) in todaysSchedules.enumerated() {
                       totalSeconds += schedule.totalDurationSeconds
                       if index < todaysSchedules.count - 1 {
                           totalSeconds += interVideoPause
                       }
                   }
                   
                   totalScheduledMinutes = totalSeconds / 60
                   
                   // Calculate completed time
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
                   
                   // ✅ ADD THIS - für Progress Ring:
                   dailyProgress = completedMinutes > 0 && targetMinutes > 0 ?
                       Double(completedMinutes) / Double(targetMinutes) : 0.0
                   
                   // 🔍 DEBUG:
                   print("🎯 dailyProgress aktualisiert!")
                   print("   Completed Minutes: \(completedMinutes)")
                   print("   Target Minutes: \(targetMinutes)")
                   print("   Progress: \(Int(dailyProgress * 100))%")
                   
                   canAddMoreVideos = remainingMinutes > 0
                   
               } catch {
                   print("❌ Error calculating progress: \(error)")
                   self.error = error
               }
           }
    // MARK: - Add Video
    
    func addVideo(
        _ video: Video,
        for user: User,
        customRepetitions: Int? = nil,
        customPauseSeconds: Int? = nil
    ) {
        let nextIndex = (todaysSchedules.map { $0.orderIndex }.max() ?? -1) + 1
        
        let schedule = VideoSchedule(
            scheduledDate: Date(),
            orderIndex: nextIndex,
            video: video,
            customRepetitions: customRepetitions,
            customPauseSeconds: customPauseSeconds,
            user: user
        )
        
        modelContext.insert(schedule)
        
        do {
            try modelContext.save()
            loadToday(for: user)
        } catch {
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
        let descriptor = FetchDescriptor<UserPreferences>()
        guard let allPreferences = try? modelContext.fetch(descriptor) else { return nil }
        return allPreferences.first
    }
    
    // MARK: - Remove Video
    
    func removeSchedule(_ schedule: VideoSchedule, for user: User) {
        modelContext.delete(schedule)
        
        let remaining = todaysSchedules
            .filter { $0.id != schedule.id }
            .sorted { $0.orderIndex < $1.orderIndex }
        
        for (index, remainingSchedule) in remaining.enumerated() {
            remainingSchedule.orderIndex = index
        }
        
        do {
            try modelContext.save()
            loadToday(for: user)
        } catch {
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
        }
        
        do {
            try modelContext.save()
            calculateProgress(for: user)  // ✅ Das update auch dailyProgress!
        } catch {
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
    
    // MARK: - Complete Schedule ✅ NEU
    func completeSchedule(scheduleId: UUID, for user: User) {
        print("✅ COMPLETE Schedule: \(scheduleId)")
        
        guard let schedule = todaysSchedules.first(where: { $0.id == scheduleId }) else {
            print("❌ Schedule \(scheduleId) nicht gefunden!")
            return
        }
        
        schedule.isCompleted = true
        schedule.completedAt = Date()
        
        do {
            try modelContext.save()
            loadToday(for: user)  // ← Refresh Haken + Ring!
            print("✅ Schedule \(scheduleId) MARKED COMPLETE!")
            print("🎯 dailyProgress: \(Int(dailyProgress * 100))%")
        } catch {
            print("❌ completeSchedule Error: \(error)")
        }
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
}

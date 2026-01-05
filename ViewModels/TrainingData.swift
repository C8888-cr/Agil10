/*
import Foundation
import SwiftData
@MainActor
class TrainingData: ObservableObject {
    @Published var dailyVideos: [Video] = []
    @Published var completedVideos: [String: [Video]] = [:]
    @Published var weekPlan: [DayPlan] = []
    
    
    // ✅ AuthService aus AppDependencies holen
       private var authService: AuthService {
           AppDependencies.shared.authService
       }
       
       // ✅ Dann currentUser daraus holen
       private var currentUser: User? {
           authService.currentUser
       }
    
    
    
    // ✅ WICHTIG: Alle Videos (Bundle + User)
    var allVideos: [Video] {
        return dailyVideos // Später erweitern mit User-Videos
    }
    
    private let weeklySettings: WeeklySettings
  //  private let dateFormatter: DateFormatter
    
    init(weeklySettings: WeeklySettings) {
        self.weeklySettings = weeklySettings
        
     //   self.dateFormatter = DateFormatter()
    //    self.dateFormatter.dateFormat = "yyyy-MM-dd"
        
 
        initializeWeekPlan()
        
        }
    
    
    // MARK: - Week Plan Initialization
    
    private func initializeWeekPlan() {
        _ = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    }
    
    // MARK: - Video Generation
    
    /// Tägliche Videos basierend auf gewählter Zeit generieren
    func generateDailyVideos() {
        _ = weeklySettings.dailyTargetMinutes
   //     dailyVideos = generateVideosForDuration(targetMinutes: targetMinutes)
   
    }
    

   
    
  
    

  
    
    // MARK: - Video Completion
    
    func completeVideo(_ video: Video, rating: Int) {
        if let index = dailyVideos.firstIndex(where: { $0.id == video.id }) {
            dailyVideos[index].isWatched = true
            dailyVideos[index].rating = rating
        
        }
        let dateKey = Date().formatDateKey()
      //  let dateKey = formatDateKey(Date())
        let updatedVideo = video
        updatedVideo.isWatched = true
        updatedVideo.rating = rating
        
        if completedVideos[dateKey] == nil {
            completedVideos[dateKey] = []
        }
        completedVideos[dateKey]?.append(updatedVideo)
      
    }
    
    func markVideoAsWatched(_ videoId: UUID) {
        if let index = dailyVideos.firstIndex(where: { $0.id == videoId }) {
            dailyVideos[index].isWatched = true
           
            let dateKey = Date().formatDateKey()
        //    let dateKey = dateFormatter.string(from: Date())
            if completedVideos[dateKey] == nil {
                completedVideos[dateKey] = []
            }
            completedVideos[dateKey]?.append(dailyVideos[index])
            
    
        }
    }
    
    func markVideoAsUnwatched(_ videoId: UUID) {
        if let index = dailyVideos.firstIndex(where: { $0.id == videoId }) {
            dailyVideos[index].isWatched = false
       
            let dateKey = Date().formatDateKey()
         //   let dateKey = dateFormatter.string(from: Date())
            completedVideos[dateKey]?.removeAll(where: { $0.id == videoId })
            
  
        }
    }
    
    // MARK: - Progress Tracking
    func getRemainingMinutes(for date: Date = Date()) -> Int {
        let watchedToday = dailyVideos.filter { video in
            guard let completedAt = video.completedAt else { return false }
            return Calendar.current.isDate(completedAt, inSameDayAs: date)
        }
        let completedMinutes = watchedToday.reduce(into: 0) { $0 += $1.durationSeconds }
        return max(0, weeklySettings.dailyTargetMinutes - completedMinutes)
    }
    
/*
    func getRemainingMinutes(for date: Date = Date()) -> Int {
        let dateKey = formatDateKey(date)
        let completed = completedVideos[dateKey] ?? []
        let completedMinutes = completed.reduce(0) { $0 + $1.durationInMinutes }
        return max(0, userSettings.dailyTrainingMinutes - completedMinutes)
    }
*/
    func getTotalPlannedMinutes() -> Int {
        return dailyVideos.reduce(into: 0) { $0 += $1.durationSeconds }
    }
    func getTodaysProgress(for date: Date = Date()) -> Double {
        let watchedToday = dailyVideos.filter { video in
            guard let completedAt = video.completedAt else { return false }
            return Calendar.current.isDate(completedAt, inSameDayAs: date)
        }
        let completedMinutes = watchedToday.reduce(into: 0) { $0 += $1.durationSeconds }
        guard weeklySettings.dailyTargetMinutes > 0 else { return 0 }
        return min(1.0, Double(completedMinutes) / Double(weeklySettings.dailyTargetMinutes))
    }
  /*  func getTodaysProgress(for date: Date = Date()) -> Double {
        let dateKey = formatDateKey(date)
        let completed = completedVideos[dateKey] ?? []
        let completedMinutes = completed.reduce(0) { $0 + $1.durationInMinutes }
        
        guard userSettings.dailyTrainingMinutes > 0 else { return 0 }
        return min(1.0, Double(completedMinutes) / Double(userSettings.dailyTrainingMinutes))
    }*/

    // MARK: - Video Filtering
    
    func getUnwatchedVideos() -> [Video] {
        return dailyVideos.filter { !$0.isWatched }
    }
    
    func getWatchedVideos() -> [Video] {
        return dailyVideos.filter { $0.isWatched }
    }
    
    func getVideosByType() -> [ExerciseCategory: [Video]] {
        return Dictionary(grouping: dailyVideos) { $0.category }
    }
    
    func getExerciseTypeStats() -> [ExerciseCategory: Int] {
        var stats: [ExerciseCategory: Int] = [:]
        for video in dailyVideos {
            stats[video.category, default: 0] += video.loopDurationSeconds
        }
        return stats
    }
    
    // MARK: - Week Plan Management
    
    func addVideoToToday(_ video: Video) {
        let today = currentDayName()
        
        guard let index = weekPlan.firstIndex(where: { $0.dayName == today }) else {
            return
        }
        
        if remainingMinutesToday > 0 {
            weekPlan[index].videos.append(video)
        
        }
    }
    
    func removeVideo(_ video: Video, from dayName: String) {
        guard let dayIndex = weekPlan.firstIndex(where: { $0.dayName == dayName }),
              let videoIndex = weekPlan[dayIndex].videos.firstIndex(where: { $0.id == video.id }) else {
            return
        }
        
        weekPlan[dayIndex].videos.remove(at: videoIndex)
      
    }
    
    var remainingMinutesToday: Int {
        let today = currentDayName()
        guard let todayPlan = weekPlan.first(where: { $0.dayName == today }) else {
            return weeklySettings.dailyTargetMinutes
        }
        
        let totalMinutes = todayPlan.videos.reduce(0) { $0 + $1.durationSeconds }
        let remaining = weeklySettings.dailyTargetMinutes - totalMinutes
        return max(0, remaining)
    }
    
    private func currentDayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        formatter.locale = Locale(identifier: "de_DE")
        let dayName = formatter.string(from: Date())
        return String(dayName.prefix(2))
    }
    
    // MARK: - Utility
    
    func reset() {
        dailyVideos.removeAll()
        completedVideos.removeAll()
        weekPlan.removeAll()
        initializeWeekPlan()
     
        generateDailyVideos()
    }
    
    func refreshVideos() {
        generateDailyVideos()
    }
    
    // MARK: - Persistence
    
 
    
 
    
 //   private func formatDateKey(_ date: Date) -> String {
 //       return dateFormatter.string(from: date)
 //   }
}
*/

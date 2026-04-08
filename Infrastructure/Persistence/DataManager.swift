import Foundation
import SwiftData
/// Zentrale Verwaltung des ModelContext und App-weiter Utilities
@MainActor
final class DataManager: ObservableObject {
    
    // MARK: - Properties
    
    /// SwiftData ModelContext für alle Datenoperationen
    let modelContext: ModelContext
    private weak var session: SessionManager?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, session: SessionManager? = nil) {
           self.modelContext = modelContext
           self.session = session
       }
    
    // MARK: - Utility Methods
    
    /// Holt den aktuellen User aus dem Context
    func getCurrentUser() -> User? {
          guard let userId = session?.currentUser?.id else { return nil }
          
          let descriptor = FetchDescriptor<User>(
              predicate: #Predicate<User> { user in
                  user.id == userId
              }
          )
          return try? modelContext.fetch(descriptor).first
      }
    
    /// Speichert alle Änderungen im Context
    func save() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
    
    /// Verwirft alle ungespeicherten Änderungen
    func rollback() {
        modelContext.rollback()
    }
    
    /// Löscht alle Daten (z.B. bei Logout/Reset)
    func deleteAllData() throws {
        // Videos löschen
        try modelContext.delete(model: Video.self)
        
        // Schedules löschen
        try modelContext.delete(model: VideoSchedule.self)
        
        // Preferences löschen
        try modelContext.delete(model: UserPreferences.self)
        
        // User NICHT löschen (AuthService kümmert sich darum)
        
        try save()
    }
}
// MARK: - Convenience Methods
extension DataManager {
    
    /// Prüft ob heute ein aktiver Trainingstag ist
    func isTodayActiveDay(for user: User) -> Bool {
        guard let preferences = user.preferences else { return false }
        
        let calendar = Calendar.current
        let today = Date()
        let firstWeekday = calendar.firstWeekday
        let rawWeekday = calendar.component(.weekday, from: today)
        let todayDayOfWeek = (rawWeekday - firstWeekday + 7) % 7
        
        guard let todayGoal = preferences.getGoalFor(dayOfWeek: todayDayOfWeek) else {
            return false
        }
        
        return todayGoal.targetMinutes > 0
    }
    
    /// Gibt alle Videos zurück (für Library)
    func fetchAllVideos() throws -> [Video] {
        let descriptor = FetchDescriptor<Video>(
            sortBy: [SortDescriptor(\.title)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Gibt alle Schedules für einen User zurück
    func fetchSchedules(for user: User, from startDate: Date, to endDate: Date) throws -> [VideoSchedule] {
        let userId = user.id
        
        let descriptor = FetchDescriptor<VideoSchedule>(
            predicate: #Predicate<VideoSchedule> { schedule in
                schedule.scheduledDate >= startDate &&
                schedule.scheduledDate < endDate
            },
            sortBy: [SortDescriptor(\.scheduledDate), SortDescriptor(\.orderIndex)]
        )
        
        let allSchedules = try modelContext.fetch(descriptor)
        return allSchedules.filter { $0.user?.id == userId }
    }
}

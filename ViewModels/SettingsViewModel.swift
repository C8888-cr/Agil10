
import SwiftUI
import SwiftData
import Combine
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var preferences: UserPreferences
    @Published var currentDayGoal: DayGoal?
    @Published var error: Error?
    
   let modelContext: ModelContext
    let user: User
    
    // ✅ ModelContext als Parameter!
    init(user: User, modelContext: ModelContext) {
        self.user = user
        self.modelContext = modelContext
        
        if let prefs = user.preferences {
            self.preferences = prefs  // ✅ DEINE bestehenden weeklyGoals laden!
        } else {
            let newPrefs = UserPreferences(user: user)  // ✅ DEIN Init mit 30 Min!
            
            // ✅ ALLE auf 0 setzen (überschreibt dein Init):
            newPrefs.weeklyGoals = (0..<7).map { day in
                DayGoal(dayOfWeek: day, targetMinutes: 0, interVideoPauseSeconds: 30)
            }
            
            modelContext.insert(newPrefs)
            user.preferences = newPrefs
            self.preferences = newPrefs
            try? modelContext.save()
            print("✅ UserPreferences mit 0 Min Goals erstellt!")
        }
        
        loadGoalForDay(0)
    }

        
    
    func loadGoalForDay(_ day: Int) {
        currentDayGoal = preferences.getGoalFor(dayOfWeek: day)
    }
    
    func saveGoal() {
        do {
            try modelContext.save()
            print("✅ Goal gespeichert")
        } catch {
            self.error = error
        }
    }
    
    func savePreferences() {
        do {
            try modelContext.save()
            print("✅ Preferences gespeichert")
        } catch {
            self.error = error
        }
    }

    
}

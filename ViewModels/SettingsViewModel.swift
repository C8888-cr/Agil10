
import SwiftUI
import SwiftData
import Combine
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var preferences: UserPreferences
    @Published var currentDayGoal: DayGoal?
    @Published var error: Error?
    @Published var currentUser: User?
    
    
   let modelContext: ModelContext
   
    
    // ✅ KEIN let user mehr!
        init(modelContext: ModelContext, currentUser: User? = nil) {
            self.modelContext = modelContext
            self.currentUser = currentUser
            
            // ✅ Vorher Preferences laden oder Dummy erstellen
            if let user = currentUser, let prefs = user.preferences {
                self.preferences = prefs
            } else {
                // ✅ Dummy Preferences ohne User (für Preview/Init)
                self.preferences = UserPreferences()  // ← Dein Init ohne User-Parameter!
                print("✅ Dummy UserPreferences erstellt (kein User)")
            }
            
            loadGoalForDay(0)
        }
    
    // ✅ User später setzen (nach Login)
        func setUser(_ user: User) {
            currentUser = user
            if let prefs = user.preferences {
                preferences = prefs
            } else {
                // Erstelle Preferences für echten User
                let newPrefs = UserPreferences(user: user)
                newPrefs.weeklyGoals = (0..<7).map { day in
                    DayGoal(dayOfWeek: day, targetMinutes: 0, interVideoPauseSeconds: 30)
                }
                modelContext.insert(newPrefs)
                user.preferences = newPrefs
                preferences = newPrefs
                try? modelContext.save()
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

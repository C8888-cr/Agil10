
import SwiftUI
import SwiftData
import Combine
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var preferences: UserPreferences
    @Published var currentDayGoal: DayGoal?
    @Published var error: Error?
    
    
    
    let modelContext: ModelContext
    
    
    // ✅ AuthService aus AppDependencies holen
    private var authService: AuthService {
        AppDependencies.shared.authService
    }
    
    // ✅ Dann currentUser daraus holen
    private var currentUser: User? {
        authService.currentUser
    }
    
    
    
    // ✅ INIT: Lade Preferences vom eingeloggten User
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.preferences = UserPreferences()
        
        
        guard let user = authService.currentUser else {
            print("⚠️ No user"); return
        }
        
        // fatalError("❌ App erfordert eingeloggten User")
        
        // ✅ Lade existierende Preferences ODER erstelle neue mit 0-Werten
        if let existing = user.preferences {
            self.preferences = existing
        } else {
            // Erstelle neue Preferences mit 0-Werten
            let newPrefs = UserPreferences(user: user)
            newPrefs.weeklyGoals = (0..<7).map { day in
                DayGoal(dayOfWeek: day, targetMinutes: 0, interVideoPauseSeconds: 30)
            }
            modelContext.insert(newPrefs)
            user.preferences = newPrefs
            self.preferences = newPrefs
            
            try? modelContext.save()
        }
    }


    
    
    
    // ✅ User später setzen (nach Login)
        func setUser(_ user: User) {
         
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

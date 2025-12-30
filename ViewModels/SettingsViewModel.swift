
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
        
        // ✅ Temporäre Preferences (werden überschrieben)
        self.preferences = UserPreferences(userId: UUID())
        
        guard let user = authService.currentUser else {
            print("⚠️ No user logged in")
            return
        }
        
        print("🔧 SettingsViewModel init for user: \(user.email)")
        print("   User ID: \(user.id)")
        
        // ✅ User aus Context holen
        let userId = user.id
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        guard let userInContext = try? modelContext.fetch(userDescriptor).first else {
            print("❌ User nicht im Context gefunden!")
            return
        }
        
        if let existing = userInContext.preferences {
            print("✅ Existing preferences found")
            self.preferences = existing
        } else {
            print("🆕 Creating new preferences for user")
            let newPrefs = UserPreferences(userId: userInContext.id)
            newPrefs.weeklyGoals = (0..<7).map { day in
                DayGoal(dayOfWeek: day, targetMinutes: 0, interVideoPauseSeconds: 30)
            }
            
            // ✅ WICHTIG: Erst insert, DANN zuweisen!
            modelContext.insert(newPrefs)
            userInContext.preferences = newPrefs
            self.preferences = newPrefs
            
            do {
                try modelContext.save()
                print("✅ New preferences saved & assigned to user")
            } catch {
                print("❌ Save failed: \(error)")
            }
        }
    }

    
    
    
    func setUser(_ user: User) {
        print("🔧 setUser called for: \(user.email)")
        
        // ✅ User aus Context holen
        let userId = user.id
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        guard let userInContext = try? modelContext.fetch(userDescriptor).first else {
            print("❌ User nicht im Context!")
            return
        }
        
        if let prefs = userInContext.preferences {
            print("✅ User hat bereits Preferences")
            preferences = prefs
        } else {
            print("🆕 Creating new preferences")
            let newPrefs = UserPreferences(userId: userInContext.id)
            newPrefs.weeklyGoals = (0..<7).map { day in
                DayGoal(dayOfWeek: day, targetMinutes: 0, interVideoPauseSeconds: 30)
            }
            
            modelContext.insert(newPrefs)
            userInContext.preferences = newPrefs
            preferences = newPrefs
            
            try? modelContext.save()
        }
        
        loadGoalForDay(0)
    }

        
    
    func loadGoalForDay(_ day: Int) {
        currentDayGoal = preferences.getGoalFor(dayOfWeek: day)
    }
    
    func saveGoal() {
        print("💾 SAVE GOAL START")
        
        guard let user = currentUser else {
            print("❌ No current user!")
            return
        }
        
        // ✅ User aus Context holen
        let userId = user.id
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        guard let userInContext = try? modelContext.fetch(userDescriptor).first else {
            print("❌ User nicht im Context!")
            return
        }
        
        print("   UserPreferences ID: \(preferences.id)")
        print("   UserPreferences userId: \(preferences.userId)")
        print("   User ID: \(userInContext.id)")
        
        // ✅ Sicherstellen dass userId stimmt
        if preferences.userId != userInContext.id {
            print("⚠️ FIXING userId mismatch!")
            preferences.userId = userInContext.id
        }
        
        // ✅ Sicherstellen dass User die Preferences hat
        if userInContext.preferences == nil {
            print("⚠️ User has no preferences - assigning!")
            userInContext.preferences = preferences
        }
        
        do {
            try modelContext.save()
            print("✅ Goal gespeichert")
            
            // ✅ Verify
            if let prefs = userInContext.preferences {
                print("🔍 User.preferences nach Save: EXISTS")
                print("   - Preferences ID: \(prefs.id)")
                print("   - Goals count: \(prefs.weeklyGoals.count)")
            } else {
                print("❌ User.preferences nach Save: STILL NIL!")
            }
            
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
            print("📢 Notification sent")
            
        } catch {
            print("❌ Save failed: \(error)")
            self.error = error
        }
    }
    
    func savePreferences() {
           print("💾 SAVE PREFERENCES")
           print("   UserPreferences ID: \(preferences.id)")
           print("   Goals count: \(preferences.weeklyGoals.count)")
           
           do {
               try modelContext.save()
               print("✅ Preferences gespeichert")
               
               // ✅ Notification senden
               NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
               print("📢 Notification sent: preferencesDidChange")
               
           } catch {
               print("❌ Save failed: \(error)")
               self.error = error
           }
       }
   }

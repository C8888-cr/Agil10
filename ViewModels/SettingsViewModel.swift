
import SwiftUI
import SwiftData
import Combine

/*
@MainActor
class SettingsViewModel: ObservableObject {
    
    @Published var selectedDayIndex: Int = 0
    @Published var selectedDayGoal: DayGoal?
    
    
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
    
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.preferences = UserPreferences(userId: UUID())
        
        print("🔧 SettingsViewModel.init() START")
        
        guard let user = authService.currentUser else {
            print("⚠️ No user logged in")
            return
        }
        
        print("👤 User gefunden: \(user.email) | ID: \(user.id)")
        print("🔍 Vorher user.preferences: \(user.preferences != nil ? "EXISTS" : "NIL")")
        
        // ✅ FORCE CREATE:
        if user.preferences == nil {
            let newPrefs = UserPreferences(userId: user.id)
            newPrefs.weeklyGoals
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

        
/* alte version
    func loadGoalForDay(_ day: Int) {
        currentDayGoal = preferences.getGoalFor(dayOfWeek: day)
    }
    */

    func saveGoal(forDayIndex dayIndex: Int) {
        guard let authUser = currentUser else { return }
        
        print("🔍 saveGoal DEBUG:")
        print("  authUser: \(authUser.email)")
        print("  authUser.preferences: \(authUser.preferences != nil)")
        
        guard let userPrefs = authUser.preferences else {
            print("❌ CRASH: authUser.preferences immer noch nil!")
            return
        }
        
        let realDayGoal = userPrefs.getGoalFor(dayOfWeek: dayIndex)!
        let oldMinutes = realDayGoal.targetMinutes
        
        realDayGoal.targetMinutes = currentDayGoal?.targetMinutes ?? 30
        
        print("📈 Tag \(dayIndex): \(oldMinutes) → \(realDayGoal.targetMinutes) Min")
        
        try? modelContext.save()
        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
    }



    func loadGoalForDay(_ dayIndex: Int) {
        selectedDayIndex = dayIndex
        selectedDayGoal = preferences.getGoalFor(dayOfWeek: dayIndex)
        print("📅 Geladen: Tag \(dayIndex) → \(selectedDayGoal?.targetMinutes ?? 0) Min")
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
    func debugDayGoals() {
        print("🔍 DEBUG: Wöchentliche Ziele:")
        
        guard let user = currentUser else {
            print("❌ No user!")
            return
        }
        
        let userIdString = user.id.uuidString
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id.uuidString == userIdString  // ← FIX!
            }
        )

        
        guard let userInContext = try? modelContext.fetch(userDescriptor).first,
              let userPrefs = userInContext.preferences else {
            print("❌ No preferences!")
            return
        }
        
        for i in 0..<7 {
            if let goal = userPrefs.getGoalFor(dayOfWeek: i) {
                print("📅 Tag \(i) (Mo=0): \(goal.targetMinutes) Min | Pause: \(goal.interVideoPauseSeconds)s")
            }
        }
    }


   }
*/


/*

//Ki-Versuch

import SwiftUI
import SwiftData
import Combine
@MainActor
class SettingsViewModel: ObservableObject {
    
    @Published var selectedDayIndex: Int = 0
    @Published var selectedDayGoal: DayGoal?
    @Published var preferences: UserPreferences
    @Published var currentDayGoal: DayGoal?
    @Published var error: Error?
    let modelContext: ModelContext
    
    // ✅ AuthService aus AppDependencies holen
    private var authService: AuthService {
        AppDependencies.shared.authService
    }
    
    // ✅ User aus Context holen (mit Relationships!)
    private var currentUserInContext: User? {
        guard let userId = authService.currentUser?.id else { return nil }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.preferences = UserPreferences(userId: UUID())
        
        print("🔧 SettingsViewModel.init() START")
        
        guard let user = authService.currentUser else {
            print("⚠️ No user logged in")
            return
        }
        
        print("👤 User gefunden: \(user.email) | ID: \(user.id)")
        
        // ✅ Direkt setUser aufrufen
        setUser(user)
    }
    
    func setUser(_ user: User) {
        print("🔧 setUser called for: \(user.email)")
        
        // ✅ User aus Context holen
        guard let userInContext = currentUserInContext else {
            print("❌ User nicht im Context!")
            return
        }
        
        print("🔍 Vorher user.preferences: \(userInContext.preferences != nil ? "EXISTS" : "NIL")")
        
        if let prefs = userInContext.preferences {
            print("✅ User hat bereits Preferences")
            preferences = prefs
        } else {
            print("🆕 Creating new preferences")
            let newPrefs = UserPreferences(userId: userInContext.id)
            newPrefs.weeklyGoals = (0..<7).map { day in
                DayGoal(dayOfWeek: day, targetMinutes: 30, interVideoPauseSeconds: 30)
            }
            
            modelContext.insert(newPrefs)
            userInContext.preferences = newPrefs
            preferences = newPrefs
            
            do {
                try modelContext.save()
                print("✅ Neue Preferences gespeichert und mit User verknüpft")
            } catch {
                print("❌ Save failed: \(error)")
            }
        }
        
        loadGoalForDay(0)
    }
    // ✅ FIX: Nutze currentUserInContext statt authService.currentUser
    func saveGoal(forDayIndex dayIndex: Int) {
        guard let userInContext = currentUserInContext else {
            print("❌ User nicht im Context!")
            return
        }
        
        print("🔍 saveGoal DEBUG:")
        print("  userInContext: \(userInContext.email)")
        print("  userInContext.preferences: \(userInContext.preferences != nil)")
        
        guard let userPrefs = userInContext.preferences else {
            print("❌ CRASH: userInContext.preferences immer noch nil!")
            return
        }
        
        guard let realDayGoal = userPrefs.getGoalFor(dayOfWeek: dayIndex) else {
            print("❌ Kein DayGoal für Tag \(dayIndex)!")
            return
        }
        
        let oldMinutes = realDayGoal.targetMinutes
        
        // ✅ Wert aus currentDayGoal oder selectedDayGoal übernehmen
        let newMinutes = currentDayGoal?.targetMinutes ?? selectedDayGoal?.targetMinutes ?? 30
        realDayGoal.targetMinutes = newMinutes
        
        print("📈 Tag \(dayIndex): \(oldMinutes) → \(realDayGoal.targetMinutes) Min")
        
        do {
            try modelContext.save()
            print("✅ Goal gespeichert!")
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        } catch {
            print("❌ Save failed: \(error)")
            self.error = error
        }
    }
    func loadGoalForDay(_ dayIndex: Int) {
        selectedDayIndex = dayIndex
        selectedDayGoal = preferences.getGoalFor(dayOfWeek: dayIndex)
        currentDayGoal = preferences.getGoalFor(dayOfWeek: dayIndex)
        print("📅 Geladen: Tag \(dayIndex) → \(selectedDayGoal?.targetMinutes ?? 0) Min")
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
    
    func debugDayGoals() {
        print("🔍 DEBUG: Wöchentliche Ziele:")
        
        guard let userInContext = currentUserInContext else {
            print("❌ No user!")
            return
        }
        
        guard let userPrefs = userInContext.preferences else {
            print("❌ No preferences!")
            return
        }
        
        for i in 0..<7 {
            if let goal = userPrefs.getGoalFor(dayOfWeek: i) {
                print("📅 Tag \(i) (Mo=0): \(goal.targetMinutes) Min | Pause: \(goal.interVideoPauseSeconds)s")
            }
        }
    }
}
*/

//2. KI-Versuch
/*
❌ WAS IST WEG?

1. ✂️ selectedDayIndex — brauchst du nicht
2. ✂️ selectedDayGoal — brauchst du nicht
3. ✂️ currentDayGoal — brauchst du nicht
4. ✂️ loadGoalForDay() — brauchst du nicht mehr
5. ✂️ savePreferences() — redundant zu saveGoal()
6. ✂️ Alle Kopier-Logik in saveGoal() — nicht mehr nötig!
*/

/*
import SwiftUI
import SwiftData
import Combine
@MainActor
class SettingsViewModel: ObservableObject {
    
    @Published var preferences: UserPreferences
    @Published var error: Error?
    
    let modelContext: ModelContext
    
    // ✅ AuthService aus AppDependencies holen
    private var authService: AuthService {
        AppDependencies.shared.authService
    }
    
    // ✅ User aus Context holen (mit Relationships!)
    private var currentUserInContext: User? {
        guard let userId = authService.currentUser?.id else { return nil }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.preferences = UserPreferences(userId: UUID())
        
        print("🔧 SettingsViewModel.init() START")
        
        guard let user = authService.currentUser else {
            print("⚠️ No user logged in")
            return
        }
        
        print("👤 User gefunden: \(user.email) | ID: \(user.id)")
        
        // ✅ Direkt setUser aufrufen
        setUser(user)
    }
    
    func setUser(_ user: User) {
        print("🔧 setUser called for: \(user.email)")
        
        // ✅ User aus Context holen
        guard let userInContext = currentUserInContext else {
            print("❌ User nicht im Context!")
            return
        }
        
        print("🔍 Vorher user.preferences: \(userInContext.preferences != nil ? "EXISTS" : "NIL")")
        
        if let prefs = userInContext.preferences {
            print("✅ User hat bereits Preferences")
            preferences = prefs
        } else {
            print("🆕 Creating new preferences")
            let newPrefs = UserPreferences(userId: userInContext.id)
            newPrefs.weeklyGoals = (0..<7).map { day in
                DayGoal(dayOfWeek: day, targetMinutes: 30, interVideoPauseSeconds: 30)
            }
            
            modelContext.insert(newPrefs)
            userInContext.preferences = newPrefs
            preferences = newPrefs
            
            do {
                try modelContext.save()
                print("✅ Neue Preferences gespeichert und mit User verknüpft")
            } catch {
                print("❌ Save failed: \(error)")
            }
        }
    }
    
    // ✅ EINFACH: Nur noch speichern, keine Kopier-Logik mehr!
    func saveGoal(forDayIndex dayIndex: Int) {
        // ✅ DEBUG: Zeig mir den ECHTEN Wert!
        guard let realGoal = preferences.getGoalFor(dayOfWeek: dayIndex) else {
            print("❌ Kein Goal für Tag \(dayIndex)!")
            return
        }
        
        print("💾 saveGoal für Tag \(dayIndex): \(realGoal.targetMinutes) Min")
        
        do {
            try modelContext.save()
            print("✅ Goal gespeichert!")
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        } catch {
            print("❌ Save failed: \(error)")
            self.error = error
        }
    }
    
    func debugDayGoals() {
        print("🔍 DEBUG: Wöchentliche Ziele:")
        
        guard let userInContext = currentUserInContext else {
            print("❌ No user!")
            return
        }
        
        guard let userPrefs = userInContext.preferences else {
            print("❌ No preferences!")
            return
        }
        
        for i in 0..<7 {
            if let goal = userPrefs.getGoalFor(dayOfWeek: i) {
                print("📅 Tag \(i) (Mo=0): \(goal.targetMinutes) Min | Pause: \(goal.interVideoPauseSeconds)s")
            }
        }
    }
}
*/
import SwiftUI
import SwiftData
import Combine
@MainActor
class SettingsViewModel: ObservableObject {
    
    @Published var preferences: UserPreferences
    @Published var error: Error?
    
    let modelContext: ModelContext
    let authService: AuthService  // ✅ Als Property speichern
    
    // ✅ User aus Context holen (mit Relationships!)
    private var currentUserInContext: User? {
        guard let userId = authService.currentUser?.id else { return nil }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
    
    // ✅ AuthService als Parameter übergeben
    init(modelContext: ModelContext, authService: AuthService) {
        self.modelContext = modelContext
        self.authService = authService  // ✅ Speichern!
        
        // ✅ Temporäre Initialisierung
        self.preferences = UserPreferences(userId: UUID())
        
        print("🔧 SettingsViewModel.init() START")
        print("👤 AuthService.currentUser: \(authService.currentUser?.email ?? "nil")")
        
        guard let user = authService.currentUser else {
            print("⚠️ No user logged in - warte auf setUser()")
            return
        }
        
        print("✅ User gefunden: \(user.email)")
        loadOrCreatePreferences(for: user)
    }
    
    // ✅ Laden oder Erstellen von Preferences
    private func loadOrCreatePreferences(for user: User) {
        guard let userInContext = currentUserInContext else {
            print("❌ User nicht im Context!")
            return
        }
        
        if let existingPrefs = userInContext.preferences {
            print("✅ Lade existierende Preferences")
            print("🔍 Gespeicherte Ziele:")
            for (index, goal) in existingPrefs.weeklyGoals.enumerated() {
                print("   Tag \(index): \(goal.targetMinutes) Min")
            }
            preferences = existingPrefs
        } else {
            print("🆕 Erstelle neue Preferences mit Standardwerten")
            let newPrefs = UserPreferences(userId: userInContext.id)
            
            newPrefs.weeklyGoals = (0..<7).map { day in
                DayGoal(dayOfWeek: day, targetMinutes: 30, interVideoPauseSeconds: 30)
            }
            
            modelContext.insert(newPrefs)
            userInContext.preferences = newPrefs
            preferences = newPrefs
            
            do {
                try modelContext.save()
                print("✅ Neue Preferences gespeichert")
            } catch {
                print("❌ Save failed: \(error)")
                self.error = error
            }
        }
    }
    
    // ✅ Wird aufgerufen wenn User sich einloggt
    func setUser(_ user: User) {
        print("🔧 setUser called for: \(user.email)")
        loadOrCreatePreferences(for: user)
    }
    
    func saveGoal(forDayIndex dayIndex: Int) {
        guard let realGoal = preferences.getGoalFor(dayOfWeek: dayIndex) else {
            print("❌ Kein Goal für Tag \(dayIndex)!")
            return
        }
        
        print("💾 === SAVE START ===")
        print("💾 Tag \(dayIndex): \(realGoal.targetMinutes) Min, Pause: \(realGoal.interVideoPauseSeconds)s")
        print("🔍 preferences.id: \(preferences.id)")
        print("🔍 hasChanges BEFORE save: \(modelContext.hasChanges)")
        
        do {
            try modelContext.save()
            print("✅ Goal gespeichert!")
            print("🔍 hasChanges AFTER save: \(modelContext.hasChanges)")
            
            // ✅ Verifikation
            if let verification = preferences.getGoalFor(dayOfWeek: dayIndex) {
                print("✅ Verifikation - Tag \(dayIndex): \(verification.targetMinutes) Min")
            }
            
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
            print("💾 === SAVE END ===")
        } catch {
            print("❌ Save failed: \(error)")
            self.error = error
        }
    }
    
    func debugDayGoals() {
        print("🔍 === DEBUG DAY GOALS ===")
        print("🔍 preferences.id: \(preferences.id)")
        
        guard let userInContext = currentUserInContext else {
            print("❌ No user!")
            return
        }
        
        guard let userPrefs = userInContext.preferences else {
            print("❌ No preferences!")
            return
        }
        
        print("🔍 User: \(userInContext.email)")
        print("🔍 Preferences ID: \(userPrefs.id)")
        print("🔍 Weekly Goals Count: \(userPrefs.weeklyGoals.count)")
        
        for i in 0..<7 {
            if let goal = userPrefs.getGoalFor(dayOfWeek: i) {
                print("📅 Tag \(i): \(goal.targetMinutes) Min | Pause: \(goal.interVideoPauseSeconds)s | Active: \(goal.isActive)")
            } else {
                print("❌ Tag \(i): Kein Goal!")
            }
        }
        print("🔍 === END DEBUG ===")
    }
}

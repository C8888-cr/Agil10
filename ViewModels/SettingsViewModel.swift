
import SwiftUI
import SwiftData
import Combine
import UserNotifications


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
            NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
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
    
    // In SettingsViewModel — neue Funktionen
    
    func addVideoWithScope(
        _ video: Video,
        to date: Date,
        for user: User,
        scope: ScheduleScope,
        progressVM: ProgressViewModel,
        customRepetitions: Int? = nil,
        customPauseSeconds: Int? = nil,
        customLoopDuration: Int? = nil
    ) {
        let calendar = Calendar.current
        let dayOfWeek = (calendar.component(.weekday, from: date) + 5) % 7
        let rule = preferences.getGoalFor(dayOfWeek: dayOfWeek)?.recurrenceRule ?? .single
        
        // 1. Heute eintragen — über ProgressVM wie bisher
        progressVM.addVideo(
            video,
            to: date,
            for: user,
            customRepetitions: customRepetitions,
            customPauseSeconds: customPauseSeconds,
            customLoopDuration: customLoopDuration
        )
        
        // 2. Falls allFuture: zukünftige Termine generieren
        guard scope == .allFuture, rule != .single else { return }
        
        let horizon = calendar.date(byAdding: .month, value: 3, to: date)!
        let futureDates = generateFutureDates(
            for: rule,
            from: date,
            dayOfWeek: dayOfWeek,
            to: horizon
        )
        
        // OrderIndex: nach bestehenden Schedules einreihen
        let existingCount = progressVM.todaysSchedules.count
        let groupId = UUID()
        
        for (index, futureDate) in futureDates.enumerated() {
            let futureSchedule = VideoSchedule(
                scheduledDate: calendar.startOfDay(for: futureDate),
                orderIndex: existingCount + index,
                video: video,
                customRepetitions: customRepetitions,   // ✅ NEU
                customPauseSeconds: customPauseSeconds, // ✅ NEU
                customLoopDurationSeconds: customLoopDuration, // ✅ NEU
                user: user,
                recurrenceRule: rule,
                recurrenceGroupID: groupId // gleiche Gruppe für alle Future-Schedules
            )
            futureSchedule.isAutoGenerated = true
            futureSchedule.dayOfWeek = dayOfWeek
            modelContext.insert(futureSchedule)
        }
        
        try? modelContext.save()
        print("📅 \(futureDates.count) zukünftige Schedules für '\(video.title)' ergänzt")
    }
    
    func removeScheduleWithScope(
        _ schedule: VideoSchedule,
        for user: User,
        scope: ScheduleScope,
        progressVM: ProgressViewModel
    ) {
        // 1. Schedule normal löschen — über ProgressVM wie bisher
        progressVM.removeSchedule(schedule, for: user)
        
        // 2. Falls allFuture: zukünftige Schedules mit gleichem Video löschen
        guard scope == .allFuture,
              let video = schedule.video else { return }
        
        let videoId = video.id
        let now = Date()
        let groupId = schedule.recurrenceGroupID
        
        // ✅ Über recurrenceGroupID filtern — sauberer als userId-Predicate
        let descriptor = FetchDescriptor<VideoSchedule>(
            predicate: #Predicate<VideoSchedule> { s in
                s.recurrenceGroupID == groupId &&
                s.scheduledDate > now
            }
        )
        
        guard let futureSchedules = try? modelContext.fetch(descriptor) else { return }
        print("🗑️ Lösche \(futureSchedules.count) zukünftige Schedules für Video \(videoId)")
        futureSchedules.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
    
    // Private Hilfsfunktion
    private func generateFutureDates(
        for rule: RecurrenceRule,
        from start: Date,
        dayOfWeek: Int,
        to end: Date
    ) -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        var current = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: start)
        )!

        // dayIndex 0=Mo → weekday 2, ..., 6=So → weekday 1
        let targetWeekday = dayOfWeek == 6 ? 1 : dayOfWeek + 2

        while current <= end {
            let weekday = calendar.component(.weekday, from: current)

            switch rule {
            case .daily:
                dates.append(current)
                   current = calendar.date(byAdding: .day, value: 1, to: current)!
                
            case .weekly:
                if weekday == targetWeekday {
                    dates.append(current)
                }
                current = calendar.date(byAdding: .day, value: 1, to: current)!

            case .monthly:
                if weekday == targetWeekday {
                    dates.append(current)
                    current = calendar.date(byAdding: .month, value: 1, to: current)!
                } else {
                    current = calendar.date(byAdding: .day, value: 1, to: current)!
                }

            case .single:
                return []
            }
        }
        return dates
    }
    // In SettingsViewModel ergänzen — nach saveGoal()

    func updateRecurrenceRule(_ rule: RecurrenceRule, forDayIndex dayIndex: Int, user: User) {
        guard let goal = preferences.getGoalFor(dayOfWeek: dayIndex) else { return }
        
        let oldRule = goal.recurrenceRule
        
        // ✅ Erst alles löschen — BEVOR neue Regel gesetzt wird
        deleteAutoSchedules(forDayIndex: dayIndex, user: user)
        
        // Dann Regel setzen
        goal.recurrenceRule = rule
        saveGoal(forDayIndex: dayIndex)
        
        print("🔄 Rule: \(oldRule.rawValue) → \(rule.rawValue) für Tag \(dayIndex)")
        
        // Dann neu generieren
        if rule != .single {
            generateSchedulesForRule(rule, dayIndex: dayIndex, goal: goal, user: user)
        }
    }

    private func deleteAutoSchedules(forDayIndex dayIndex: Int, user: User) {
        let now = Date()
        let userId = user.id

        // Alle zukünftigen VideoSchedules dieses Users holen
        let descriptor = FetchDescriptor<VideoSchedule>(
            predicate: #Predicate<VideoSchedule> { s in
                s.isAutoGenerated == true &&
                s.scheduledDate > now &&
                s.dayOfWeek == dayIndex
            }
        )

        guard let schedules = try? modelContext.fetch(descriptor) else { return }
        
        // User-Filter in Swift (wegen optionalem Relationship)
        let userSchedules = schedules.filter { $0.user?.id == userId }
        
        print("🗑️ Lösche \(userSchedules.count) auto-Schedules für Tag \(dayIndex)")
        userSchedules.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }

    private func generateSchedulesForRule(
        _ rule: RecurrenceRule,
        dayIndex: Int,
        goal: DayGoal,
        user: User
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let horizon = calendar.date(byAdding: .month, value: 3, to: today)!

        // Template-Schedules für diesen Tag holen
        let descriptor = FetchDescriptor<VideoSchedule>(
            predicate: #Predicate<VideoSchedule> { s in
                s.isAutoGenerated == false &&
                s.dayOfWeek == dayIndex
            }
        )

        guard let templateSchedules = try? modelContext.fetch(descriptor) else { return }
        let userTemplates = templateSchedules.filter { $0.user?.id == user.id }

        guard !userTemplates.isEmpty else {
            print("⚠️ Keine Template-Videos für Tag \(dayIndex) — erst Videos hinzufügen!")
            return
        }

        // ✅ FIX: Korrekte Zieldaten — NUR für dayIndex, nicht alle Tage
        let futureDates = generateFutureDates(
            for: rule,
            from: today,
            dayOfWeek: dayIndex,  // ← Wird jetzt korrekt gefiltert
            to: horizon
        )

        print("📅 Plane \(futureDates.count) Termine für Tag \(dayIndex) mit Regel \(rule.rawValue)")

        let groupId = UUID()
        var addedCount = 0

        for futureDate in futureDates {
            let normalizedDate = calendar.startOfDay(for: futureDate)

            for template in userTemplates {
                guard let video = template.video else { continue }

                let newSchedule = VideoSchedule(
                    scheduledDate: normalizedDate,
                    orderIndex: template.orderIndex,
                    video: video,
                    customRepetitions: template.customRepetitions,
                    customPauseSeconds: template.customPauseSeconds,
                    customLoopDurationSeconds: template.customLoopDurationSeconds,
                    user: user,
                    recurrenceRule: rule,
                    recurrenceGroupID: groupId
                )
                newSchedule.isAutoGenerated = true
                newSchedule.dayOfWeek = dayIndex
                modelContext.insert(newSchedule)
                addedCount += 1
            }
        }

        try? modelContext.save()
        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        print("✅ \(addedCount) Schedules generiert für Tag \(dayIndex)")
    }
    
    // MARK: - Daily Template

    // Computed Property — alle Templates des Users
    var dailyTemplates: [VideoSchedule] {
        let userId = authService.currentUser?.id
        let descriptor = FetchDescriptor<VideoSchedule>(
            predicate: #Predicate<VideoSchedule> { s in
                s.isTemplate == true
            }
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return all.filter { $0.templateUserId == userId }
    }

    func addDailyTemplate(
        video: Video,
        repetitions: Int,
        loopDurationSeconds: Int,
        pauseSeconds: Int,
        dayIndex: Int = 0,
        user: User
    ) {
        let template = VideoSchedule(
            scheduledDate: Date(), // Datum irrelevant für Templates
            orderIndex: dailyTemplates.count,
            video: video,
            customRepetitions: repetitions,
            customPauseSeconds: pauseSeconds,
            customLoopDurationSeconds: loopDurationSeconds,
            user: user
        )
        template.isTemplate = true
        template.templateUserId = user.id
        template.dayOfWeek = dayIndex 
        
        modelContext.insert(template)
        try? modelContext.save()
        objectWillChange.send()
        print("📋 Template hinzugefügt: \(video.title)")
    }

    func removeDailyTemplate(_ schedule: VideoSchedule, user: User) {
        modelContext.delete(schedule)
        try? modelContext.save()
        objectWillChange.send()
        print("🗑️ Template entfernt")
    }

    func clearDailyTemplates(for user: User) {
        dailyTemplates.forEach { modelContext.delete($0) }
        try? modelContext.save()
        print("🗑️ Alle Templates gelöscht")
    }

    // Wendet Templates auf alle aktiven Tage an
    func applyTemplatesToActiveDays(for user: User, progressVM: ProgressViewModel) {
        let templates = dailyTemplates
        guard !templates.isEmpty else {
            print("⚠️ Keine Templates vorhanden")
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let horizon = calendar.date(byAdding: .month, value: 3, to: today)!
        let groupId = UUID()
        
        // Alle aktiven Tage (targetMinutes > 0 und isActive)
        let activeDayIndices = preferences.weeklyGoals
            .filter { $0.isActive && $0.targetMinutes > 0 }
            .map { $0.dayOfWeek }
        
        guard !activeDayIndices.isEmpty else {
            print("⚠️ Keine aktiven Trainingstage")
            return
        }
        
        // Erst alle alten auto-Schedules löschen
        for dayIndex in activeDayIndices {
            deleteAutoSchedules(forDayIndex: dayIndex, user: user)
        }
        
        // Für jeden Tag neue Schedules erstellen
        var current = calendar.date(byAdding: .day, value: 1, to: today)!
        var addedCount = 0
        
        while current <= horizon {
            let weekday = calendar.component(.weekday, from: current)
            // weekday: 1=So, 2=Mo... → dayIndex: 0=Mo, 6=So
            let dayIndex = weekday == 1 ? 6 : weekday - 2
            
            if activeDayIndices.contains(dayIndex) {
                for template in templates {
                    guard let video = template.video else { continue }
                    
                    let newSchedule = VideoSchedule(
                        scheduledDate: calendar.startOfDay(for: current),
                        orderIndex: template.orderIndex,
                        video: video,
                        customRepetitions: template.customRepetitions,
                        customPauseSeconds: template.customPauseSeconds,
                        customLoopDurationSeconds: template.customLoopDurationSeconds,
                        user: user,
                        recurrenceRule: .daily,
                        recurrenceGroupID: groupId
                    )
                    newSchedule.isAutoGenerated = true
                    newSchedule.dayOfWeek = dayIndex
                    modelContext.insert(newSchedule)
                    addedCount += 1
                }
            }
            
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        try? modelContext.save()
        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        print("✅ \(addedCount) Daily-Schedules aus Vorlage erstellt")
    }
    
    func applyWeekPlan(
        startDate: Date,
        weekPlan: [Int: [WeekPlannerSheet.PlannedVideo]],
        rule: RecurrenceRule,
        strategy: MergeStrategy,  // ✅ NEU
        user: User
    ) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: startDate)
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone.current
        let start = calendar.date(from: components) ?? calendar.startOfDay(for: startDate)
        let horizon = calendar.date(byAdding: .month, value: 3, to: start)!
        
        // ✅ Löschen je nach Strategie
        switch strategy {
        case .replaceAll:
            // Alles löschen — auto UND manuell
            let descriptor = FetchDescriptor<VideoSchedule>(
                predicate: #Predicate<VideoSchedule> { s in
                    s.scheduledDate >= start &&
                    s.isTemplate == false
                }
            )
            if let existing = try? modelContext.fetch(descriptor) {
                let toDelete = existing.filter { $0.user?.id == user.id }
                print("🗑️ Ersetze \(toDelete.count) Schedules ab \(start)")
                toDelete.forEach { modelContext.delete($0) }
                try? modelContext.save()
            }
            
        case .addToPlan:
            // Nur auto-Schedules löschen — manuelle behalten
            let descriptor = FetchDescriptor<VideoSchedule>(
                predicate: #Predicate<VideoSchedule> { s in
                    s.scheduledDate >= start &&
                    s.isAutoGenerated == true &&
                    s.isTemplate == false
                }
            )
            if let existing = try? modelContext.fetch(descriptor) {
                let toDelete = existing.filter { $0.user?.id == user.id }
                print("🗑️ Lösche \(toDelete.count) auto-Schedules, manuelle bleiben")
                toDelete.forEach { modelContext.delete($0) }
                try? modelContext.save()
            }
        }
        
        // Rest bleibt gleich — Schedules generieren
        let groupId = UUID()
        var addedCount = 0
        
        switch rule {
        case .daily:
            guard let dailyVideos = weekPlan[0], !dailyVideos.isEmpty else {
                print("⚠️ Keine Daily-Videos konfiguriert")
                break
            }
            
            var current = start
            while current <= horizon {
                let weekday = calendar.component(.weekday, from: current)
                let dayIndex = weekday == 1 ? 6 : weekday - 2
                
                let goal = self.preferences.weeklyGoals.first { $0.dayOfWeek == dayIndex }
                let isActiveDay = goal?.isActive ?? false
                let hasMinutes = (goal?.targetMinutes ?? 0) > 0
                
                if isActiveDay && hasMinutes {
                    for (index, planned) in dailyVideos.enumerated() {
                        let schedule = VideoSchedule(
                            scheduledDate: current,
                            orderIndex: index,
                            video: planned.video,
                            customRepetitions: planned.repetitions,
                            customPauseSeconds: planned.pauseSeconds,
                            customLoopDurationSeconds: planned.loopDurationSeconds,
                            user: user,
                            recurrenceRule: .daily,
                            recurrenceGroupID: groupId
                        )
                        schedule.isAutoGenerated = true
                        schedule.dayOfWeek = dayIndex
                        modelContext.insert(schedule)
                        addedCount += 1
                    }
                }
                current = calendar.date(byAdding: .day, value: 1, to: current)!
            }
            
        case .weekly:
            for (dayIndex, plannedVideos) in weekPlan {
                guard !plannedVideos.isEmpty else { continue }
                
                let targetWeekday = dayIndex == 6 ? 1 : dayIndex + 2
                var current = start
                while calendar.component(.weekday, from: current) != targetWeekday {
                    current = calendar.date(byAdding: .day, value: 1, to: current)!
                }
                
                while current <= horizon {
                    for (index, planned) in plannedVideos.enumerated() {
                        let schedule = VideoSchedule(
                            scheduledDate: current,
                            orderIndex: index,
                            video: planned.video,
                            customRepetitions: planned.repetitions,
                            customPauseSeconds: planned.pauseSeconds,
                            customLoopDurationSeconds: planned.loopDurationSeconds,
                            user: user,
                            recurrenceRule: .weekly,
                            recurrenceGroupID: groupId
                        )
                        schedule.isAutoGenerated = true
                        schedule.dayOfWeek = dayIndex
                        modelContext.insert(schedule)
                        addedCount += 1
                    }
                    current = calendar.date(byAdding: .weekOfYear, value: 1, to: current)!
                }
            }
            
        default:
            break
        }

        for i in 0..<7 {
            preferences.getGoalFor(dayOfWeek: i)?.recurrenceRule = rule
        }
        try? modelContext.save()
        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        print("✅ WeekPlan angewendet: \(addedCount) Schedules ab \(start) | Strategie: \(strategy)")
    }
    // In SettingsViewModel ergänzen:

    func recurrenceRule(for date: Date) -> RecurrenceRule {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)  // lokale Zeit!
        let dayIndex = (weekday + 5) % 7  // 0=Mo, 6=So
        return preferences.getGoalFor(dayOfWeek: dayIndex)?.recurrenceRule ?? .single
    }
    // MARK: - Notifications

    func scheduleAllReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard preferences.notificationsEnabled else { return }

        for goal in preferences.weeklyGoals {
            guard goal.isActive,
                  goal.targetMinutes > 0,
                  goal.reminderEnabled else { continue }

            let time = goal.hasIndividualReminderTime
                ? goal.reminderTime
                : preferences.reminderTime

            let content = UNMutableNotificationContent()
            content.title = "Zeit für dein Training"
            content.body = "Du hast heute \(goal.targetMinutes) Minuten geplant."
            content.sound = .default

            var components = DateComponents()
            components.hour = Calendar.current.component(.hour, from: time)
            components.minute = Calendar.current.component(.minute, from: time)
            // dayOfWeek: 0=Mo → weekday 2, ..., 6=So → weekday 1
            components.weekday = goal.dayOfWeek == 6 ? 1 : goal.dayOfWeek + 2

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: "reminder_day_\(goal.dayOfWeek)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error { print("❌ Notification Error Tag \(goal.dayOfWeek): \(error)") }
            }
        }

        print("🔔 Notifications neu geplant")
    }
}

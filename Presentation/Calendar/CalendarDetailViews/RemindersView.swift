
import SwiftUI
import SwiftData
import UserNotifications
import AgilCore


struct RemindersView: View {
    
    @State private var showWeekPlanner = false
    @State private var weekPlannerRule: RecurrenceRule = .daily
    @State private var weekPlannerRuleToShow: RecurrenceRule? = nil
    
    
    @EnvironmentObject var videoLibraryVM: VideoLibraryViewModel
    @EnvironmentObject var progressVM: ProgressViewModel
    
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showResetAlert = false
    @State private var selectedDay: Int = 0
    @State private var showNotificationDeniedAlert = false
    // ✅ Computed property - holt automatisch das richtige Goal
    
    
    private var currentDayGoal: DayGoal? {
        settingsVM.preferences.weeklyGoals.first { $0.dayOfWeek == selectedDay }
    }
    
    var body: some View {
        Form {
       
                notificationsSection
            
            
            
        }
        .navigationTitle("Einstellungen")
        
       
        
        .alert("Benachrichtigungen deaktiviert", isPresented: $showNotificationDeniedAlert) {
            Button("Zu den Einstellungen") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Um Erinnerungen zu erhalten, aktiviere Benachrichtigungen für Agil unter Einstellungen → Agil → Mitteilungen.")
        }
    }
    
  
    private var notificationsSection: some View {
        Section {
            // Globaler Toggle
            Toggle(isOn: Binding(
                get: { settingsVM.preferences.notificationsEnabled },
                set: { newValue in
                    if newValue {
                        UNUserNotificationCenter.current().requestAuthorization(
                            options: [.alert, .sound, .badge]
                        ) { granted, _ in
                            DispatchQueue.main.async {
                                settingsVM.preferences.notificationsEnabled = granted
                                if granted { settingsVM.scheduleAllReminders() }
                                settingsVM.saveGoal(forDayIndex: selectedDay)
                            }
                        }
                    } else {
                        settingsVM.preferences.notificationsEnabled = false
                        showNotificationDeniedAlert = true  // ← neu
                        settingsVM.saveGoal(forDayIndex: selectedDay)
                    }
                }
            )) {
                Label("Erinnerungen aktiv", systemImage: "bell.fill")
            }
            .tint(themeManager.currentTheme.accentColor)
            
            if settingsVM.preferences.notificationsEnabled {
                // Standard-Uhrzeit — nur sichtbar wenn mind. ein Tag KEINEN individuellen Wert hat
                if settingsVM.preferences.weeklyGoals.contains(where: {
                    $0.targetMinutes > 0 && $0.isActive && !$0.hasIndividualReminderTime
                }) {
                    DatePicker(
                        "Standard-Uhrzeit",
                        selection: Binding(
                            get: { settingsVM.preferences.reminderTime },
                            set: { settingsVM.preferences.reminderTime = $0; saveDayGoal() }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                }
                
                // Alle Tage als Liste
                ForEach(WeekDay.allCases, id: \.self) { day in
                    if let goal = settingsVM.preferences.getGoalFor(dayOfWeek: day.dayNumber) {
                        reminderRow(for: day, goal: goal)
                    }
                }
            }
        } header: {
            Label("Benachrichtigungen", systemImage: "app.badge")
        } footer: {
            Text("Standard-Uhrzeit gilt für alle Tage ohne individuelle Einstellung.")
                .font(.caption)
        }
    }
    
    private func reminderRow(for day: WeekDay, goal: DayGoal) -> some View {
        let hasTraining = goal.targetMinutes > 0 && goal.isActive
        
        return HStack(spacing: 12) {
            // Tagesname
            Text(day.shortName)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 28, alignment: .leading)
                .foregroundColor(hasTraining ? .primary : .secondary)
            
            if hasTraining {
                if goal.hasIndividualReminderTime {
                    // Individuelle Zeit + Zurücksetzen
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { goal.reminderTime },
                            set: {
                                goal.reminderTime = $0
                                goal.reminderEnabled = true          // ← NEU: sicherstellen dass aktiv
                                settingsVM.saveGoal(forDayIndex: goal.dayOfWeek)  // ← statt saveDayGoal()
                                settingsVM.scheduleAllReminders()    // ← NEU
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    
                    Button {
                        goal.hasIndividualReminderTime = false
                        goal.reminderTime = settingsVM.preferences.reminderTime
                        settingsVM.saveGoal(forDayIndex: goal.dayOfWeek)  // ← statt saveDayGoal()
                        settingsVM.scheduleAllReminders()                           } label: {
                            Text("Standard")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                        .buttonStyle(.plain)
                    
                } else {
                    // Standard greift — Tipp aktiviert individuelle Zeit
                    Spacer()
                    Text(settingsVM.preferences.reminderTime.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        goal.hasIndividualReminderTime = true
                        settingsVM.saveGoal(forDayIndex: goal.dayOfWeek)  // ← statt saveDayGoal()
                        settingsVM.scheduleAllReminders()
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Spacer()
                Text(goal.targetMinutes == 0 ? "Kein Training" : "Inaktiv")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private var reminderFooterText: some View {
        Group {
            if let dayGoal = currentDayGoal,
               dayGoal.targetMinutes > 0,
               dayGoal.isActive,
               dayGoal.reminderEnabled {
                let time = dayGoal.hasIndividualReminderTime
                ? dayGoal.reminderTime
                : settingsVM.preferences.reminderTime
                let suffix = dayGoal.hasIndividualReminderTime ? " (individuell)" : " (Standard)"
                Text("\(WeekDay.allCases[selectedDay].fullName): Erinnerung um \(time.formatted(date: .omitted, time: .shortened))\(suffix)")
            } else {
                Text("")
            }
        }
        .font(.caption)
    }
    // MARK: - Helper Functions


    private func saveDayGoal() {
        print("💾 Speichere Tag \(selectedDay): \(currentDayGoal?.targetMinutes ?? 0) Min")
        settingsVM.saveGoal(forDayIndex: selectedDay)
    }
}



// MARK: - Notification Extension
extension Notification.Name {
    static let preferencesDidChange = Notification.Name("preferencesDidChange")
}
#Preview {
    let container = try! ModelContainer(
        for: User.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

       let userRepository = UserRepository(modelContext: container.mainContext)
       let authenticator = LocalAuthBiometricAuthenticator()
       let preferences = UserDefaultsBiometricPreferences()
       let unlockUseCase = UnlockAppUseCase(
           authenticator: authenticator,
           preferences: preferences
       )
    let sessionManager = SessionManager(
                authService: LocalAuthService(),
                userRepository: userRepository,
           unlockUseCase: unlockUseCase,
           preferences: preferences
       )
    let repository = VideoScheduleRepository(modelContext: context)
    
    SettingsView()
        .environmentObject(SettingsViewModel(
            modelContext: context,
            session: sessionManager,
            addScheduleUseCase: AddScheduleUseCase(repository: repository),
            removeScheduleUseCase: RemoveScheduleUseCase(repository: repository)
        ))
        .environmentObject(sessionManager)
}



import SwiftUI
import SwiftData
import UserNotifications


struct SettingsView: View {
    
    @State private var showWeekPlanner = false
    @State private var weekPlannerRule: RecurrenceRule = .daily
    @State private var weekPlannerRuleToShow: RecurrenceRule? = nil
    
    @State private var showDailyTemplate = false
    @EnvironmentObject var videoLibraryVM: VideoLibraryViewModel
    @EnvironmentObject var progressVM: ProgressViewModel 
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.modelContext) var modelContext
    
    @State private var showResetAlert = false
    @State private var selectedDay: Int = 0
    @State private var showNotificationDeniedAlert = false
    // ✅ Computed property - holt automatisch das richtige Goal
    
    
    private var currentDayGoal: DayGoal? {
        settingsVM.preferences.weeklyGoals.first { $0.dayOfWeek == selectedDay }
    }
    
    var body: some View {
        Form {
            daySelectionSection
            if currentDayGoal != nil {
                trainingSection
                recurrenceSection 
                notificationsSection
            }
            appInfoSection
            dangerZoneSection
        }
        .navigationTitle("Einstellungen")

        .sheet(item: $weekPlannerRuleToShow) { rule in
            WeekPlannerSheet(
                rule: rule,  // ← kommt direkt aus dem item, kein State-Timing-Problem
                onSave: { startDate, plan, strategy in
                    if let user = authService.currentUser {
                        if let goal = settingsVM.preferences.getGoalFor(dayOfWeek: selectedDay) {
                            goal.recurrenceRule = rule
                        }
                        settingsVM.saveGoal(forDayIndex: selectedDay)
                        settingsVM.applyWeekPlan(
                            startDate: startDate,
                            weekPlan: plan,
                            rule: rule,
                            strategy: strategy,
                            user: user
                        )
                    }
                    weekPlannerRuleToShow = nil
                },
                onCancel: {
                    weekPlannerRuleToShow = nil
                }
            )
            .environmentObject(settingsVM)
            .environmentObject(videoLibraryVM)
            .environmentObject(authService)
        }
        .sheet(isPresented: $showDailyTemplate) {
            DailyTemplateView(rule: currentDayGoal?.recurrenceRule ?? .daily)
                .environmentObject(settingsVM)
                .environmentObject(videoLibraryVM)
                .environmentObject(authService)
                .environmentObject(progressVM)
        }
          .alert("Alle Daten löschen?", isPresented: $showResetAlert) {
              Button("Abbrechen", role: .cancel) { }
              Button("Löschen", role: .destructive) { resetAllData() }
          } message: {
              Text("Diese Aktion kann nicht rückgängig gemacht werden.")
          }
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
    
    // MARK: - Sections
    
    private var daySelectionSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WeekDay.allCases, id: \.self) { day in
                        dayButton(day)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        } header: {
            Label("Wähle einen Tag", systemImage: "calendar")
        }
    }
    
    private func dayButton(_ day: WeekDay) -> some View {
        let goal = dayGoal(for: day)
        let isSelected = selectedDay == day.dayNumber
        let minutes = goal?.targetMinutes ?? 0
        let isActive = minutes > 0
        
        return Button(action: {
            selectedDay = day.dayNumber
        }) {
            VStack(spacing: 4) {
                Text(day.shortName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(
                        isSelected ? .white : (isActive ? .primary : .secondary)
                    )
                
                Text(isActive ? "\(minutes) Min" : "–")
                    .font(.caption2)
                    .foregroundColor(
                        isSelected ? .white.opacity(0.8) :
                        isActive ? .accent : .secondary
                    )
                
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.8) : Color.clear)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Color.white.opacity(0.8) :
                                Color.gray.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            }
            .frame(minWidth: 44)  // ✅ minWidth statt maxWidth
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected ? Color.accent :
                        isActive ? Color.gray.opacity(0.1) :
                        Color.gray.opacity(0.05)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .opacity(isActive ? 1.0 : 0.6)
    }
    
    private var trainingSection: some View {
        Section {
            if let dayGoal = currentDayGoal {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Trainings-Ziel")
                            .font(.subheadline)
                        Spacer()
                        Text("\(dayGoal.targetMinutes) Min")
                            .font(.subheadline)
                            .foregroundColor(.accent)
                            .fontWeight(.semibold)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(dayGoal.targetMinutes) },
                            set: { newValue in
                                dayGoal.targetMinutes = Int(newValue)
                                dayGoal.isActive = dayGoal.targetMinutes > 0
                                saveDayGoal()
                            }
                        ),
                        in: 0...60,
                        step: 5
                    )
                    .tint(.accent)
                    
                    Text("Wähle zwischen 0 und 60 Minuten tägliches Training")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Label("Training für \(WeekDay.allCases[selectedDay].fullName)", systemImage: "figure.strengthtraining.traditional")
        }
    }
    

    private var recurrenceSection: some View {
        Section {
            if let dayGoal = currentDayGoal {
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Aktuell gewählte Regel anzeigen
                    HStack {
                        Label(dayGoal.recurrenceRule.rawValue,
                              systemImage: dayGoal.recurrenceRule.icon)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accent)
                        Spacer()
                    }
                    .padding(.bottom, 4)
                    
                    // Alle Optionen als Buttons
                    ForEach(RecurrenceRule.allCases.filter { $0 != .monthly }, id: \.self) { rule in
                        recurrenceButton(rule: rule, currentRule: dayGoal.recurrenceRule) {
                            if rule == .daily || rule == .weekly {
                                weekPlannerRule = rule
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    weekPlannerRuleToShow = rule
                                }
                            } else {
                                if let user = authService.currentUser {
                                    for i in 0..<7 {
                                        settingsVM.updateRecurrenceRule(
                                            rule,
                                            forDayIndex: i,
                                            user: user
                                        )
                                    }
                                }
                            }
                        }
                    }
                    // Daily-Vorlage Button — nur bei .daily sichtbar
                    if dayGoal.recurrenceRule == .daily || dayGoal.recurrenceRule == .weekly {
                        Button {
                            showDailyTemplate = true
                        } label: {
                            HStack {
                                Label(
                                    dayGoal.recurrenceRule == .daily ? "Tages-Vorlage bearbeiten" : "Wochen-Vorlage bearbeiten",
                                    systemImage: "doc.text.fill"
                                )
                                .foregroundColor(.accent)
                                Spacer()
                                
                                let count = settingsVM.dailyTemplates.count
                                if count > 0 {
                                    Text("\(count) Videos")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accent.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accent.opacity(0.3), lineWidth: 1.5)
                        )
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    
                    // Beschreibung
                    Text(dayGoal.recurrenceRule.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                }  // ← VStack Ende
                .padding(.vertical, 8)
            }  // ← if let Ende
        } header: {
            Label(
                "Wiederholung für \(WeekDay.allCases[selectedDay].fullName)",
                systemImage: "repeat"
            )
        } footer: {
            recurrenceFooterText
        
    
        }
    }

    private func recurrenceButton(
        rule: RecurrenceRule,
        currentRule: RecurrenceRule,
        action: @escaping () -> Void
    ) -> some View {
        let isSelected = rule == currentRule
        
        return Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: rule.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : .accent)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.accent : Color.accent.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(rule.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accent)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accent.opacity(0.08) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    // ✅ Footer Text je nach gewählter Regel
    private var recurrenceFooterText: some View {
        Group {
            if let dayGoal = currentDayGoal {
                switch dayGoal.recurrenceRule {
                case .single:
                    Text("Videos werden nur für den ausgewählten Tag geplant.")
                case .daily:
                    Text("Videos werden täglich automatisch in deinen Plan aufgenommen.")
                case .weekly:
                    Text("Videos wiederholen sich jeden \(WeekDay.allCases[selectedDay].fullName) automatisch.")
                case .monthly:
                    Text("Videos wiederholen sich jeden \(WeekDay.allCases[selectedDay].fullName) im Monat automatisch.")
                }
            } else {
                Text("")
            }
        }
        .font(.caption)
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
            .tint(.accent)

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
                            .foregroundColor(.accent)
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
                            .foregroundColor(.accent)
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
    // ✅ Goal für einen bestimmten Tag holen
    private func dayGoal(for day: WeekDay) -> DayGoal? {
        settingsVM.preferences.weeklyGoals.first { $0.dayOfWeek == day.dayNumber }
    }
    private func saveDayGoal() {
        print("💾 Speichere Tag \(selectedDay): \(currentDayGoal?.targetMinutes ?? 0) Min")
        settingsVM.saveGoal(forDayIndex: selectedDay)
    }
    
    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text("2025.01")
                    .foregroundColor(.secondary)
            }
        } header: {
            Label("App Info", systemImage: "info.circle")
        }
    }
    
    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label("Alle Daten zurücksetzen", systemImage: "trash.fill")
            }
        } header: {
            Label("Daten", systemImage: "exclamationmark.triangle")
        } footer: {
            Text("Löscht alle Trainingsdaten und Einstellungen")
                .font(.caption)
        }
    }
    
    private func resetAllData() {
        // Implementieren Sie Ihre Reset-Logik hier
    }
}
// MARK: - WeekDay Enum
enum WeekDay: String, CaseIterable, Identifiable {
    case monday = "Mo"
    case tuesday = "Di"
    case wednesday = "Mi"
    case thursday = "Do"
    case friday = "Fr"
    case saturday = "Sa"
    case sunday = "So"
    
    var id: String { rawValue }
    var shortName: String { rawValue }
    
    var dayNumber: Int {
        switch self {
        case .monday: return 0
        case .tuesday: return 1
        case .wednesday: return 2
        case .thursday: return 3
        case .friday: return 4
        case .saturday: return 5
        case .sunday: return 6
        }
    }
    
    var fullName: String {
        switch self {
        case .monday: return "Montag"
        case .tuesday: return "Dienstag"
        case .wednesday: return "Mittwoch"
        case .thursday: return "Donnerstag"
        case .friday: return "Freitag"
        case .saturday: return "Samstag"
        case .sunday: return "Sonntag"
        }
    }
}
// MARK: - Notification Extension
extension Notification.Name {
    static let preferencesDidChange = Notification.Name("preferencesDidChange")
}
#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel(
            modelContext: ModelContext(
                try! ModelContainer(
                    for: User.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            ),
            authService: AppDependencies.shared.authService
        ))
}
#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel(
            modelContext: ModelContext(
                try! ModelContainer(
                    for: User.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            ),
            authService: AppDependencies.shared.authService
        ))
}

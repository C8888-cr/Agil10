
import SwiftUI
import SwiftData


struct SettingsView: View {
    
    @State private var showWeekPlanner = false
    @State private var weekPlannerRule: RecurrenceRule = .daily
    @State private var weekPlannerRuleToShow: RecurrenceRule? = nil
    
    @State private var showDailyTemplate = false
    @EnvironmentObject var videoLibraryVM: VideoLibraryViewModel
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.modelContext) var modelContext
    
    @State private var showResetAlert = false
    @State private var selectedDay: Int = 0
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
              DailyTemplateView()
                  .environmentObject(settingsVM)
                  .environmentObject(videoLibraryVM)
                  .environmentObject(authService)
          }
          .alert("Alle Daten löschen?", isPresented: $showResetAlert) {
              Button("Abbrechen", role: .cancel) { }
              Button("Löschen", role: .destructive) { resetAllData() }
          } message: {
              Text("Diese Aktion kann nicht rückgängig gemacht werden.")
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
                                    settingsVM.updateRecurrenceRule(
                                        rule,
                                        forDayIndex: selectedDay,
                                        user: user
                                    )
                                }
                            }
                        }
                    }
                    
                    // Daily-Vorlage Button — nur bei .daily sichtbar
                    if dayGoal.recurrenceRule == .daily {
                        Button {
                            showDailyTemplate = true
                        } label: {
                            HStack {
                                Label(
                                    "Tages-Vorlage bearbeiten",
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
            if let dayGoal = currentDayGoal {
                Toggle(isOn: Binding(
                    get: { dayGoal.isActive },
                    set: { newValue in
                        dayGoal.isActive = newValue
                        saveDayGoal()
                    }
                )) {
                    Label("Training aktiv", systemImage: "checkmark.circle.fill")
                }
                .tint(.accent)
                
                if dayGoal.isActive && dayGoal.targetMinutes > 0 {
                    Toggle(isOn: Binding(
                        get: { dayGoal.reminderEnabled },
                        set: { newValue in
                            dayGoal.reminderEnabled = newValue
                            saveDayGoal()
                        }
                    )) {
                        Label("Erinnerung aktivieren", systemImage: "bell.fill")
                    }
                    .tint(.accent)
                    
                    if dayGoal.reminderEnabled {
                        DatePicker(
                            "Uhrzeit",
                            selection: Binding(
                                get: { dayGoal.reminderTime },
                                set: { newValue in
                                    dayGoal.reminderTime = newValue
                                    saveDayGoal()
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                    }
                }
            }
        } header: {
            Label("Benachrichtigungen", systemImage: "app.badge")
        } footer: {
            Text("Erinnerungen für \(WeekDay.allCases[selectedDay].fullName)")
                .font(.caption)
        }
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

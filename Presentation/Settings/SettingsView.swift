//
//  SettingsView 2.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


import SwiftUI
import SwiftData
import AgilCore




struct SettingsView: View {
    
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
            daySelectionSection
            if currentDayGoal != nil {
                trainingSection
     
            }
            
            
        }
        .navigationTitle("Einstellungen")
        
        .sheet(item: $weekPlannerRuleToShow) { rule in
            WeekPlannerSheet(
                rule: rule,  // ← kommt direkt aus dem item, kein State-Timing-Problem
                expertModeEnabled: settingsVM.preferences.expertModeEnabled, 
                onSave: { startDate, plan, strategy in
                    if let user = session.currentUser {
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
            .environmentObject(session)
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
                            isActive ? themeManager.currentTheme.accentColor : .secondary
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
            .frame(minWidth: 44)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected ? themeManager.currentTheme.accentColor :
                            isActive ? Color.gray.opacity(0.1) :
                            Color.gray.opacity(0.05)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? themeManager.currentTheme.accentColor : Color.clear, lineWidth: 2)
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
                            .foregroundColor(themeManager.currentTheme.accentColor)
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
                    .tint(themeManager.currentTheme.accentColor)
                    
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
    
 
    // MARK: - Helper Functions
    // ✅ Goal für einen bestimmten Tag holen
    private func dayGoal(for day: WeekDay) -> DayGoal? {
        settingsVM.preferences.weeklyGoals.first { $0.dayOfWeek == day.dayNumber }
    }
    private func saveDayGoal() {
        print("💾 Speichere Tag \(selectedDay): \(currentDayGoal?.targetMinutes ?? 0) Min")
        settingsVM.saveGoal(forDayIndex: selectedDay)
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

#Preview {
    let container = try! ModelContainer(
        for: User.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    let userRepository = UserRepository(modelContext: context)
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
        .environmentObject(ThemeManager())
}


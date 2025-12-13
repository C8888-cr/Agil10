//
//  SettingsView.swift
//  Agil
//
import SwiftUI
import SwiftData
struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var showResetAlert = false
    @State private var selectedDay: Int = 0
    @State private var currentDayGoal: DayGoal?
    
    let user: User
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
      
            Form {
                daySelectionSection
                if currentDayGoal != nil {
                    trainingSection
                    notificationsSection
                }
                appInfoSection
                dangerZoneSection
            }
            .navigationTitle("Einstellungen")
            .onChange(of: selectedDay) { _, newValue in
                loadDayGoal(newValue)
            }
            .onAppear {
                loadDayGoal(selectedDay)
            }
            .alert("Alle Daten löschen?", isPresented: $showResetAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("Diese Aktion kann nicht rückgängig gemacht werden.")
            
        }
    }
    
    // MARK: - Sections
    
    private var daySelectionSection: some View {
        Section {
            HStack(spacing: 8) {
                ForEach(WeekDay.allCases, id: \.self) { day in
                    dayButton(day)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Label("Wähle einen Tag", systemImage: "calendar")
        }
    }
    
    private func dayButton(_ day: WeekDay) -> some View {
        Button(action: { selectedDay = day.dayNumber }) {
            VStack(spacing: 4) {
                Text(day.shortName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                
                Circle()
                    .fill(selectedDay == day.dayNumber ? Color.accent : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedDay == day.dayNumber ? Color.accent.opacity(0.15) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedDay == day.dayNumber ? Color.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
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
                            set: { dayGoal.targetMinutes = Int($0) }
                        ),
                        in: 0...60,
                        step: 5
                    )
                    .tint(.accent)
                    .onChange(of: dayGoal.targetMinutes) { _, _ in
                        dayGoal.isActive = dayGoal.targetMinutes > 0
                        saveDayGoal()
                    }
                    
                    Text("Wähle zwischen 0 und 60 Minuten tägliches Training")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pause zwischen Videos")
                            .font(.subheadline)
                        Spacer()
                        Text("\(dayGoal.interVideoPauseSeconds) Sek")
                            .font(.subheadline)
                            .foregroundColor(.accent)
                            .fontWeight(.semibold)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(dayGoal.interVideoPauseSeconds) },
                            set: { dayGoal.interVideoPauseSeconds = Int($0) }
                        ),
                        in: 0...120,
                        step: 5
                    )
                    .tint(.accent)
                    .onChange(of: dayGoal.interVideoPauseSeconds) { _, _ in
                        saveDayGoal()
                    }
                    
                    Text("Pausenzeit zwischen den Übungen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Label("Training für \(WeekDay.allCases[selectedDay].fullName)", systemImage: "figure.strengthtraining.traditional")
        }
    }
    
    private var notificationsSection: some View {
        Section {
            if let dayGoal = currentDayGoal {
                Toggle(isOn: Binding(
                    get: { dayGoal.isActive },
                    set: { dayGoal.isActive = $0 }
                )) {
                    Label("Training aktiv", systemImage: "checkmark.circle.fill")
                }
                .tint(.accent)
                .onChange(of: dayGoal.isActive) { _, _ in
                    saveDayGoal()
                }
                
                if dayGoal.isActive && dayGoal.targetMinutes > 0 {
                    // ✅ Pro Tag einzelne Erinnerung
                    Toggle(isOn: Binding(
                        get: { dayGoal.reminderEnabled },
                        set: { dayGoal.reminderEnabled = $0 }
                    )) {
                        Label("Erinnerung aktivieren", systemImage: "bell.fill")
                    }
                    .tint(.accent)
                    .onChange(of: dayGoal.reminderEnabled) { _, _ in
                        saveDayGoal()
                    }
                    
                    if dayGoal.reminderEnabled {
                        DatePicker(
                            "Uhrzeit",
                            selection: Binding(
                                get: { dayGoal.reminderTime },
                                set: { dayGoal.reminderTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .onChange(of: dayGoal.reminderTime) { _, _ in
                            saveDayGoal()
                        }
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
    private func loadDayGoal(_ dayNumber: Int) {
        currentDayGoal = settingsVM.preferences.getGoalFor(dayOfWeek: dayNumber)
    }
    private func saveDayGoal() {
        guard currentDayGoal != nil else { return }
        settingsVM.loadGoalForDay(selectedDay)  // ← Reload
           settingsVM.saveGoal()  // ← DURCH settingsVM!
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
    
    // MARK: - Helper Functions
    

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
#Preview {
    SettingsView(user: User(email: "test@test.com", passwordHash: "123"))
        .environmentObject(SettingsViewModel(
            user: User(email: "test@test.com", passwordHash: "123"),
            modelContext: ModelContext(
                try! ModelContainer(
                    for: User.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            )
        ))
}

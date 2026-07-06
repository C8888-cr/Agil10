//
//  NotificationSettingsSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 13.04.26.
//


// NotificationSettingsSheet.swift
import SwiftUI
import UserNotifications
import AgilCore

struct NotificationSettingsSheet: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showNotificationDeniedAlert = false
    @EnvironmentObject var themeManager: ThemeManager
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
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
                                        else { showNotificationDeniedAlert = true }
                                    }
                                }
                            } else {
                                settingsVM.preferences.notificationsEnabled = false
                                showNotificationDeniedAlert = true
                            }
                        }
                    )) {
                        Label("Erinnerungen aktiv", systemImage: "bell.fill")
                    }
                    .tint(themeManager.currentTheme.accentColor)

                    if settingsVM.preferences.notificationsEnabled {
                        if settingsVM.preferences.weeklyGoals.contains(where: {
                            $0.targetMinutes > 0 && $0.isActive && !$0.hasIndividualReminderTime
                        }) {
                            DatePicker(
                                "Standard-Uhrzeit",
                                selection: Binding(
                                    get: { settingsVM.preferences.reminderTime },
                                    set: {
                                        settingsVM.preferences.reminderTime = $0
                                        settingsVM.scheduleAllReminders()
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                        }

                        ForEach(WeekDay.allCases, id: \.self) { day in
                            if let goal = settingsVM.preferences.getGoalFor(dayOfWeek: day.dayNumber) {
                                reminderRow(for: day, goal: goal)
                            }
                        }
                    }
                } header: {
                    Label("Trainings-Erinnerungen", systemImage: "app.badge")
                } footer: {
                    Text("Standard-Uhrzeit gilt für alle Tage ohne individuelle Einstellung.")
                        .font(.caption)
                }
            }
            .navigationTitle("Erinnerungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .alert("Benachrichtigungen deaktiviert", isPresented: $showNotificationDeniedAlert) {
                Button("Zu den Einstellungen") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Aktiviere Benachrichtigungen unter Einstellungen → Agil → Mitteilungen.")
            }
        }
    }

    private func reminderRow(for day: WeekDay, goal: DayGoal) -> some View {
        let hasTraining = goal.targetMinutes > 0 && goal.isActive

        return HStack(spacing: 12) {
            Text(day.shortName)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 28, alignment: .leading)
                .foregroundColor(hasTraining ? .primary : .secondary)

            if hasTraining {
                if goal.hasIndividualReminderTime {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { goal.reminderTime },
                            set: {
                                goal.reminderTime = $0
                                goal.reminderEnabled = true
                                settingsVM.saveGoal(forDayIndex: goal.dayOfWeek)
                                settingsVM.scheduleAllReminders()
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()

                    Button {
                        goal.hasIndividualReminderTime = false
                        goal.reminderTime = settingsVM.preferences.reminderTime
                        settingsVM.saveGoal(forDayIndex: goal.dayOfWeek)
                        settingsVM.scheduleAllReminders()
                    } label: {
                        Text("Standard")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                    Text(settingsVM.preferences.reminderTime.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button {
                        goal.hasIndividualReminderTime = true
                        settingsVM.saveGoal(forDayIndex: goal.dayOfWeek)
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
}

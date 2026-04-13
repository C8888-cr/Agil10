//
//  AppointmentReminderOption.swift
//  Agil10.0
//
//  Created by Christiane Roth on 13.04.26.
//


// AppointmentReminderSheet.swift
import SwiftUI
import UserNotifications
import SwiftData

enum AppointmentReminderOption: String, CaseIterable {
    case morgens = "Morgens um 8:00 Uhr"
    case oneHour = "1 Stunde vorher"
    case twoHours = "2 Stunden vorher"
    case threeHours = "3 Stunden vorher"
    
    var icon: String {
        switch self {
        case .morgens: return "sunrise.fill"
        case .oneHour: return "clock.fill"
        case .twoHours: return "clock.fill"
        case .threeHours: return "clock.fill"
        }
    }
    
    var subtitle: String {
        switch self {
        case .morgens: return "Erinnerung am Termintag um 8:00 Uhr"
        case .oneHour: return "60 Minuten vor dem Termin"
        case .twoHours: return "120 Minuten vor dem Termin"
        case .threeHours: return "180 Minuten vor dem Termin"
        }
    }
}

struct AppointmentReminderSheet: View {
    @Bindable var user: User
    let appointments: [Appointment]
    @Environment(\.dismiss) private var dismiss
    @State private var showPermissionAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: Binding(
                        get: { user.appointmentReminderEnabled },
                        set: { newValue in
                            if newValue {
                                requestPermissionAndEnable()
                            } else {
                                user.appointmentReminderEnabled = false
                                AppointmentNotificationService.scheduleReminders(
                                    for: appointments,
                                    enabled: true,
                                    reminderTime: user.appointmentReminderTime,
                                    mode: user.appointmentReminderMode    // NEU
                                )
                            }
                        }
                    )) {
                        Label("Erinnerungen aktiv", systemImage: "bell.badge.fill")
                    }
                    .tint(.accent)
                } header: {
                    Label("Termin-Erinnerungen", systemImage: "calendar.badge.clock")
                }

                if user.appointmentReminderEnabled {
                    Section {
                        ForEach(AppointmentReminderOption.allCases, id: \.self) { option in
                            Button {
                                selectOption(option)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: option.icon)
                                        .foregroundStyle(.accent)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(option.rawValue)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Text(option.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if isSelected(option) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.accent)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Label("Zeitpunkt", systemImage: "clock")
                    } footer: {
                        Text("Du erhältst eine Erinnerung für jeden bevorstehenden Termin.")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Termin-Erinnerungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .alert("Benachrichtigungen deaktiviert", isPresented: $showPermissionAlert) {
                Button("Zu den Einstellungen") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Bitte aktiviere Benachrichtigungen unter Einstellungen → Agil → Mitteilungen.")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func isSelected(_ option: AppointmentReminderOption) -> Bool {
        switch option {
        case .morgens:
            return user.appointmentReminderMode == "morgens"
        case .oneHour:
            return user.appointmentReminderMode == "1h"
        case .twoHours:
            return user.appointmentReminderMode == "2h"
        case .threeHours:
            return user.appointmentReminderMode == "3h"
        }
    }
    
    private func selectOption(_ option: AppointmentReminderOption) {
        switch option {
        case .morgens:
            user.appointmentReminderMode = "morgens"
            user.appointmentReminderTime = Calendar.current.date(
                bySettingHour: 8, minute: 0, second: 0, of: Date()
            ) ?? Date()
        case .oneHour:
            user.appointmentReminderMode = "1h"
        case .twoHours:
            user.appointmentReminderMode = "2h"
        case .threeHours:
            user.appointmentReminderMode = "3h"
        }
        AppointmentNotificationService.scheduleReminders(
            for: appointments,
            enabled: true,
            reminderTime: user.appointmentReminderTime,
            mode: user.appointmentReminderMode    // NEU
        )
    }

    private func requestPermissionAndEnable() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    user.appointmentReminderEnabled = true
                    AppointmentNotificationService.scheduleReminders(
                        for: appointments,
                        enabled: true,
                        reminderTime: user.appointmentReminderTime,
                        mode: user.appointmentReminderMode    // NEU
                    )
                } else {
                    user.appointmentReminderEnabled = false
                    showPermissionAlert = true
                }
            }
        }
    }
}

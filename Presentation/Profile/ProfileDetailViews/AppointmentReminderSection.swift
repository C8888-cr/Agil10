

import SwiftUI
import UserNotifications
import SwiftData

struct AppointmentReminderSection: View {
    @Bindable var user: User
    let appointments: [Appointment]   // aus @Query in ProfileView übergeben
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showPermissionAlert = false

    var body: some View {
        InfoCard {
            VStack(spacing: 12) {

                // Toggle
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
                    Label("Termin-Erinnerungen", systemImage: "bell.badge.fill")
                        .fontWeight(.medium)
                }
                .tint(themeManager.currentTheme.accentColor)

                // DatePicker — nur sichtbar wenn Toggle an
                if user.appointmentReminderEnabled {
                    Divider()

                    DatePicker(
                        "Erinnerung um",
                        selection: Binding(
                            get: { user.appointmentReminderTime },
                            set: { newTime in
                                user.appointmentReminderTime = newTime
                                AppointmentNotificationService.scheduleReminders(
                                    for: appointments,
                                    enabled: true,
                                    reminderTime: user.appointmentReminderTime,
                                    mode: user.appointmentReminderMode    // NEU
                                )
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)

                    Text("Du wirst am Morgen jedes Termintages erinnert.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
            Text("Bitte aktiviere Benachrichtigungen für Agil unter Einstellungen → Agil → Mitteilungen.")
        }
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

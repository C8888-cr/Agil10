

import Foundation
import UserNotifications

struct AppointmentNotificationService {

    static let identifierPrefix = "appointment_reminder_"

    static func scheduleReminders(
        for appointments: [Appointment],
        enabled: Bool,
        reminderTime: Date,
        mode: String = "morgens"    // NEU
    ) {
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { requests in
            let ids = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix(identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)

            guard enabled else {
                print("🔕 Termin-Erinnerungen deaktiviert")
                return
            }

            let now = Date()
            let calendar = Calendar.current

            for appointment in appointments {
                guard appointment.date > now,
                      appointment.status != .cancelled else { continue }

                // Feuerzeitpunkt je nach Modus berechnen
                let fireDate: Date?
                switch mode {
                case "morgens":
                    let hour = calendar.component(.hour, from: reminderTime)
                    let minute = calendar.component(.minute, from: reminderTime)
                    fireDate = calendar.date(
                        bySettingHour: hour,
                        minute: minute,
                        second: 0,
                        of: appointment.date
                    )
                case "1h":
                    fireDate = calendar.date(byAdding: .hour, value: -1, to: appointment.date)
                case "2h":
                    fireDate = calendar.date(byAdding: .hour, value: -2, to: appointment.date)
                case "3h":
                    fireDate = calendar.date(byAdding: .hour, value: -3, to: appointment.date)
                default:
                    fireDate = nil
                }

                guard let fireDate, fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Termin heute"
                content.body = "\(appointment.timeString) Uhr – \(appointment.therapist)"
                content.sound = .default

                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: fireDate
                )

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: false
                )

                let identifier = "\(identifierPrefix)\(appointment.id.uuidString)"
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )

                center.add(request) { error in
                    if let error {
                        print("❌ Termin-Notification Fehler: \(error)")
                    } else {
                        print("🔔 Erinnerung geplant: \(appointment.therapist) am \(appointment.dateString) um \(fireDate)")
                    }
                }
            }
        }
    }
}

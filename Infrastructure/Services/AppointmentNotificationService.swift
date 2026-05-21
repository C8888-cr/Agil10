import Foundation
@preconcurrency import UserNotifications

struct AppointmentNotificationService {

    static let identifierPrefix = "appointment_reminder_"

    static func scheduleReminders(
        for appointments: [Appointment],
        enabled: Bool,
        reminderTime: Date,
        mode: String = "morgens"
    ) async {
        let center = UNUserNotificationCenter.current()

        // 1. Erst alte löschen (mit await für sichere Completion)
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let ids = requests
                    .map { $0.identifier }
                    .filter { $0.hasPrefix(identifierPrefix) }
                
                center.removePendingNotificationRequests(withIdentifiers: ids)
                continuation.resume()
            }
        }
        
        // 2. DANN neue planen (erst nach Löschen!)
        guard enabled else {
            print("🔕 Termin-Erinnerungen deaktiviert")
            return
        }

        let now = Date()
        let calendar = Calendar.current

        for appointment in appointments {
            guard appointment.date > now,
                  appointment.status != .cancelled else { continue }

            // 🆕 Daten vorher extrahieren (außerhalb Closure)
            let appointmentId = appointment.id
            let appointmentDate = appointment.date
            let appointmentTherapist = appointment.therapist
            let appointmentTimeString = appointment.timeString
            let appointmentDateString = appointment.dateString
            let appointmentDuration = appointment.durationMinutes

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
                    of: appointmentDate
                )
            case "1h":
                fireDate = calendar.date(byAdding: .hour, value: -1, to: appointmentDate)
            case "2h":
                fireDate = calendar.date(byAdding: .hour, value: -2, to: appointmentDate)
            case "3h":
                fireDate = calendar.date(byAdding: .hour, value: -3, to: appointmentDate)
            default:
                fireDate = nil
            }

            guard let fireDate, fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Termin heute"
            let endTime = appointmentDate.addingTimeInterval(TimeInterval(appointmentDuration * 60))
            let endTimeString = endTime.formatted(.dateTime.hour().minute())
            content.body = "\(appointmentTimeString) – \(endTimeString) Uhr – \(appointmentTherapist ?? "agil")"
            content.sound = .default

            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )

            let identifier = "\(identifierPrefix)\(appointmentId.uuidString)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            // 🆕 await statt completion handler
            do {
                try await center.add(request)
                print("🔔 Erinnerung geplant: \(appointmentTherapist ?? "kein Therapeut") am \(appointmentDateString) um \(fireDate)")
            } catch {
                print("❌ Termin-Notification Fehler: \(error)")
            }
        }
    }
}

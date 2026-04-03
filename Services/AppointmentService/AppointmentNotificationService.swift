//
//  AppointmentNotificationService.swift
//  Agil10.0
//
//  Created by Christiane Roth on 03.04.26.
//


//
//  AppointmentNotificationService.swift
//  Agil
//
//  Plant Erinnerungen für alle zukünftigen Termine

import Foundation
import UserNotifications

struct AppointmentNotificationService {

    static let identifierPrefix = "appointment_reminder_"

    // Alle Termin-Notifications neu planen
    static func scheduleReminders(
        for appointments: [Appointment],
        enabled: Bool,
        reminderTime: Date
    ) {
        let center = UNUserNotificationCenter.current()

        // Erst alle alten Termin-Notifications löschen
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

            let hour = calendar.component(.hour, from: reminderTime)
            let minute = calendar.component(.minute, from: reminderTime)

            for appointment in appointments {
                // Nur zukünftige, nicht abgesagte Termine
                guard appointment.date > now,
                      appointment.status != .cancelled else { continue }

                // Erinnerungszeit = heute Morgen um gewählte Uhrzeit
                guard let fireDate = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: appointment.date
                ) else { continue }

                // Nur planen wenn Feuerzeitpunkt noch in der Zukunft liegt
                guard fireDate > now else { continue }

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

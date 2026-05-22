import Foundation
import MapKit


struct DetectAppointmentChangesUseCase {
    private let repository: AppointmentRepository
    
    init(repository: AppointmentRepository) {
        self.repository = repository
    }
    
    func execute(
        parsedAppointments: [Appointment],
        emailHash: String,
        existingAppointments: [Appointment]
    ) -> AppointmentChanges {
        var changes = AppointmentChanges()
        
        // ✅ NUR zukünftige Termine berücksichtigen
        let futureAppointments = existingAppointments.filter { $0.date > Date() }
        
        // Neue und geänderte Termine erkennen
        for parsed in parsedAppointments {
            if let existing = findMatchingAppointment(parsed, in: futureAppointments) {
                // ✅ Hat sich WIRKLICH was geändert? (nicht nur emailUID)
                if hasChanges(parsed, comparedTo: existing) {
                                    // ✅ Änderungen übernehmen
                                    existing.date = parsed.date
                                    existing.therapist = parsed.therapist
                                    existing.locationName = parsed.locationName
                                    existing.locationAddress = parsed.locationAddress
                                    existing.notes = parsed.notes
                                    existing.status = .modified
                                    existing.isHighlighted = true
                                    existing.lastModified = Date()
                                    existing.emailUID = emailHash
                                    changes.modified.append(existing)
                
            } else {
                          // ✅ NEU: Unverändert
                          changes.unchanged.append(existing)
                      }
                  } else {
                      // Neuer Termin
                      parsed.emailUID = emailHash
                      changes.added.append(parsed)
                  }
              }
        
        // Gelöschte Termine erkennen (NUR zukünftige!)
        for existing in futureAppointments where existing.emailUID != nil {
            let stillExists = parsedAppointments.contains { parsed in
                isSameAppointment(parsed, as: existing)
            }
            
            if !stillExists {
                existing.status = .cancelled
                existing.isHighlighted = true
                existing.lastModified = Date()
                changes.cancelled.append(existing)
            }
        }
        
        return changes
    }
    
    private func findMatchingAppointment(
        _ appointment: Appointment,
        in list: [Appointment]
    ) -> Appointment? {
        list.first { existing in
            isSameAppointment(appointment, as: existing)
        }
    }
    
    private func isSameAppointment(
            _ a: Appointment,
            as b: Appointment
        ) -> Bool {
            // Identität eines Termins = Zeitpunkt (Tag + Uhrzeit auf die Minute).
            // Der Therapeut ist KEIN Match-Kriterium – er darf sich ändern.
            Calendar.current.isDate(a.date, equalTo: b.date, toGranularity: .minute)
        }
    
    // ✅ NEU: Prüft ob sich Details geändert haben
    private func hasChanges(
        _ parsed: Appointment,
        comparedTo existing: Appointment
    ) -> Bool {
        // Zeit geändert?
        if !Calendar.current.isDate(parsed.date, equalTo: existing.date, toGranularity: .minute) {
            return true
        }
        
        // Ort geändert?
        if parsed.locationName != existing.locationName ||
           parsed.locationAddress != existing.locationAddress {
            return true
        }
        
        
        
        
        // Notizen geändert?
                if parsed.notes != existing.notes {
                    return true
                }
                
                // Therapeut geändert? (case-insensitiv; nil ↔ Name zählt auch)
                if !sameTherapist(parsed.therapist, existing.therapist) {
                    return true
                }
                
                return false
            }
            
            /// Vergleicht zwei optionale Therapeuten-Namen case-insensitiv.
            /// nil und "" gelten als gleich; nil ↔ Name als Änderung.
            private func sameTherapist(_ a: String?, _ b: String?) -> Bool {
                let lhs = (a ?? "").trimmingCharacters(in: .whitespaces).lowercased()
                let rhs = (b ?? "").trimmingCharacters(in: .whitespaces).lowercased()
                return lhs == rhs
            }
}
struct AppointmentChanges: Identifiable {
    let id = UUID()
    
    var added: [Appointment] = []
        var modified: [Appointment] = []
        var cancelled: [Appointment] = []
        var unchanged: [Appointment] = []
        var failed: [Appointment] = []   // Import angelegt, aber Anlegen schlug fehl
    
    
    var hasChanges: Bool {
        !added.isEmpty || !modified.isEmpty || !cancelled.isEmpty
    }
    
    var totalCount: Int {
        added.count + modified.count + cancelled.count
    }
    
    var changesSummary: String {
        var messages: [String] = []
        
        if !added.isEmpty {
            messages.append("\(added.count) neu")
        }
        if !modified.isEmpty {
            messages.append("\(modified.count) geändert")
        }
        if !cancelled.isEmpty {
            messages.append("\(cancelled.count) abgesagt")
        }
        
        if !unchanged.isEmpty {
                   messages.append("\(unchanged.count) unverändert")
               }
        
        return messages.joined(separator: ", ")
    }
}

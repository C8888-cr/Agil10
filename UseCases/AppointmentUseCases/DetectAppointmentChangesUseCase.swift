//
//  DetectAppointmentChangesUseCase.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  DetectAppointmentChangesUseCase.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.10.25.
//

// Features/Appointments/UseCases/DetectAppointmentChangesUseCase.swift
import Foundation
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
          // Neue und geänderte Termine erkennen
               for parsed in parsedAppointments {
                   if let existing = findMatchingAppointment(parsed, in: existingAppointments) {
                       // Änderung erkannt?
                       if existing.emailUID != emailHash {
                           existing.status = .modified
                           existing.isHighlighted = true
                           existing.lastModified = Date()
                           existing.emailUID = emailHash
                           changes.modified.append(existing)
                       }
                   } else {
                       // Neuer Termin
                       changes.added.append(parsed)
                   }
               }
               
          let futureAppointments = existingAppointments.filter { $0.date > Date() }
        // Gelöschte Termine erkennen
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
        Calendar.current.isDate(a.date, inSameDayAs: b.date) &&
        a.therapist == b.therapist
    }
}
struct AppointmentChanges {
    var added: [Appointment] = []
    var modified: [Appointment] = []
    var cancelled: [Appointment] = []
    
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
           
           return messages.joined(separator: ", ")
       }
   }

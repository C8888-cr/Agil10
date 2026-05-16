//
//  UpdateAppointmentUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.05.26.
//


//
//  UpdateAppointmentUseCase.swift
//  Agil10.0
//
//  Aktualisiert einen bestehenden Termin in Agil + Apple-Kalender.
//

import Foundation

struct UpdateAppointmentUseCase {
    
    private let repository: AppointmentRepository
    private let calendarSync: CalendarSyncService?
    
    init(
        repository: AppointmentRepository,
        calendarSync: CalendarSyncService? = nil
    ) {
        self.repository = repository
        self.calendarSync = calendarSync
    }
    
    /// Aktualisiert einen bestehenden Termin.
    /// SwiftData persistiert die Property-Änderungen automatisch.
    /// Falls ein Calendar-Event verknüpft ist, wird der auch aktualisiert.
    func execute(
        _ appointment: Appointment,
        newDate: Date,
        newTherapist: String?,
        newLocationName: String?,
        newLocationAddress: String?,
        newLatitude: Double?,
        newLongitude: Double?,
        newNotes: String?,
        newDurationMinutes: Int
    ) async throws -> Appointment {
        
        print("✏️ === UPDATE APPOINTMENT USE CASE ===")
        print("   → ID: \(appointment.id)")
        print("   → Neue Daten: \(newDate), Dauer: \(newDurationMinutes) Min")
        
        // 1. Agil-Termin updaten (SwiftData persistiert automatisch)
        appointment.date = newDate
        appointment.therapist = newTherapist
        appointment.locationName = newLocationName
        appointment.locationAddress = newLocationAddress
        appointment.locationLatitude = newLatitude
        appointment.locationLongitude = newLongitude
        appointment.notes = newNotes
        appointment.durationMinutes = newDurationMinutes
        appointment.lastModified = Date()
        
        print("✅ Agil-Termin aktualisiert")
        
        // 2. Calendar-Event aktualisieren (wenn verknüpft + Permission)
        if let sync = calendarSync,
           sync.authorizationStatus == .authorized,
           let eventId = appointment.calendarEventIdentifier {
            do {
                // Title bauen (analog AddAppointmentUseCase)
                let baseTitle: String
                if let therapist = newTherapist, !therapist.isEmpty {
                    baseTitle = "Physio: \(therapist)"
                } else {
                    baseTitle = "Physio-Termin"
                }
                
                let title: String
                if let notes = newNotes, !notes.isEmpty {
                    title = "\(baseTitle) – \(notes)"
                } else {
                    title = baseTitle
                }
                
                let endDate = newDate.addingTimeInterval(TimeInterval(newDurationMinutes * 60))
                let location = appointment.displayLocation
                
                try await sync.updateEvent(
                    identifier: eventId,
                    title: title,
                    startDate: newDate,
                    endDate: endDate,
                    location: location,
                    notes: newNotes
                )
                
                print("✅ Calendar-Event aktualisiert: \(eventId)")
            } catch {
                // Sync-Fehler ist kein Hard-Fail – Agil-Termin ist aktualisiert
                print("⚠️ Calendar-Update fehlgeschlagen: \(error)")
            }
        }
        
        return appointment
    }
}
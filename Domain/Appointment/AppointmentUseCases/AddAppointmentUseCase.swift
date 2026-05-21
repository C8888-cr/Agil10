//
//  AddAppointmentUseCase.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//
// Features/Appointments/Domain/UseCases/AddAppointmentUseCase.swift
import Foundation
struct AddAppointmentUseCase {
    
    private let repository: AppointmentRepository
    private let session: SessionManager
    private let calendarSync: CalendarSyncService?
    
    init(
        repository: AppointmentRepository,
        session: SessionManager,
        calendarSync: CalendarSyncService? = nil
    ) {
        self.repository = repository
        self.session = session
        self.calendarSync = calendarSync
    }
    
    // ✅ Für manuelles Hinzufügen (von UI)
    func executeManual(
        date: Date,
        therapist: String?,
        locationName: String? = nil,
        locationAddress: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        notes: String? = nil,
        durationMinutes: Int = 20
    ) async throws -> Appointment {
        print("📝 addAppointmentManual called")
        
        // ✅ Nur die ID extrahieren – User-Objekt nicht über Actor-Grenzen weitergeben
           guard let userId = await MainActor.run(body: { session.currentUser?.id }) else {
               print("❌ Kein User gefunden")
               throw AppointmentError.validationFailed("Nicht eingeloggt")
           }
        print("👤 User gefunden: \(userId)")
        
        let appointment = Appointment(
            date: date,
            therapist: therapist,
            locationName: locationName,
            locationAddress: locationAddress,
            locationLatitude: latitude,
            locationLongitude: longitude,
            notes: notes,
            durationMinutes: durationMinutes,
            status: .confirmed,
            userId: userId,
            praxisId: UUID()
        )
        
        print("📅 Appointment erstellt:")
        print("   → Datum: \(date)")
        print("   → Therapeut: \(String(describing: therapist))")
        print("   → User: \(userId)")
        
        let savedAppointment = try await execute(appointment)
              
        
        // ✅ Validierung + Speichern
        // 🆕 NEU: Calendar-Sync (nur wenn Service verfügbar und Permission OK)
               if let sync = calendarSync, sync.authorizationStatus == .authorized {
                   do {
                       let endDate = savedAppointment.date.addingTimeInterval(
                           TimeInterval(savedAppointment.durationMinutes * 60)
                       )
                       let location = savedAppointment.displayLocation
                       
                       
                       // Title bauen
                       let baseTitle: String
                       if let therapist = savedAppointment.therapist, !therapist.isEmpty {
                           baseTitle = "Physio agil: \(therapist)"
                       } else {
                           baseTitle = "Physio agil"
                       }

                       // Notizen an Titel anhängen, wenn vorhanden
                       let title: String
                       if let notes = savedAppointment.notes, !notes.isEmpty {
                           title = "\(baseTitle) – \(notes)"
                       } else {
                           title = baseTitle
                       }
                       
                       print("📝 Calendar-Sync Notes-Check:")
                       print("   → appointment.notes: \(savedAppointment.notes ?? "nil")")
                       print("   → title: \(title)")
                       print("   → location: \(location ?? "nil")")
                       
                       let eventId = try await sync.createEvent(
                           title: title,
                           startDate: savedAppointment.date,
                           endDate: endDate,
                           location: location,
                           notes: savedAppointment.notes
                       )
                       savedAppointment.calendarEventIdentifier = eventId
                       try await repository.saveContext()        // 🆕 NEU
                       print("✅ calendarEventIdentifier gespeichert: \(eventId)")
                  
                   } catch {
                       // Sync-Fehler ist kein Hard-Fail – Termin ist in Agil gespeichert
                       print("⚠️ Calendar-Sync fehlgeschlagen: \(error)")
                   }
               }
               
               return savedAppointment
    }
    
    // ✅ Für Email-Import
    @discardableResult
    func execute(_ appointment: Appointment) async throws -> Appointment {
        print("\n💾 === ADD APPOINTMENT USE CASE ===")
        print("📅 Termin: \(appointment.therapist ?? "kein Therapeut") am \(appointment.date)")
        
    /*    // ✅ Validation
        guard !appointment.therapist.isEmpty else {
            print("❌ Therapeut leer")
            throw ValidationError.emptyTherapistName
        }
      */
        // ✅ GEÄNDERT: Erlaube vergangene Termine für Email-Import
        if appointment.date < Date() {
            print("⚠️ Warnung: Datum in Vergangenheit: \(appointment.date)")
            // Trotzdem erlauben (für Email-Import alter Termine)
        }
        
        print("✅ Validierung erfolgreich")
        
        // ✅ Duplikat-Check
        print("🔍 Prüfe Duplikate...")
        let isDuplicate = try await repository.checkDuplicate(
            date: appointment.date,
            therapist: appointment.therapist ?? ""
        )
        
        if isDuplicate {
            print("❌ Duplikat gefunden")
            throw AppointmentError.duplicateAppointment
        }
        
        print("✅ Kein Duplikat gefunden")
        
        // ✅ Speichern
        print("💾 Speichere in Repository...")
        do {
            try await repository.save(appointment)
            print("✅ Repository.save() erfolgreich")
            print("   → Saved with userId: \(appointment.userId!.uuidString)")
            
        } catch {
            print("❌ Repository.save() fehlgeschlagen: \(error)")  // ✅ Normale Anführungszeichen
            throw AppointmentError.saveFailed(error.localizedDescription)
        }
        
        return appointment
    }
}

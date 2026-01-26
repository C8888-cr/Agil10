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
    private let authService: AuthService
    
    init(repository: AppointmentRepository, authService: AuthService) {
        self.repository = repository
        self.authService = authService
    }
    
    // ✅ Für manuelles Hinzufügen (von UI)
    func executeManual(
        date: Date,
        therapist: String,
        locationName: String? = nil,
        locationAddress: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        notes: String? = nil
    ) async throws -> Appointment {
        print("📝 addAppointmentManual called")
        
        guard let user = await authService.currentUser else {  // ✅ GEÄNDERT: await entfernt
            print("❌ Kein User gefunden")
            throw AppointmentError.validationFailed("Nicht eingeloggt")
        }
        print("👤 User gefunden: \(user.id)")
        
        let appointment = Appointment(
            date: date,
            therapist: therapist,
            locationName: locationName,
            locationAddress: locationAddress,
            locationLatitude: latitude,
            locationLongitude: longitude,
            notes: notes,
            status: .confirmed,
            userId: user.id,
            praxisId: UUID()  // ✅ Status hinzugefügt
        )
        
        print("📅 Appointment erstellt:")
        print("   → Datum: \(date)")
        print("   → Therapeut: \(therapist)")
        print("   → User: \(user.id)")
        
        // ✅ Validierung + Speichern
        let savedAppointment = try await execute(appointment)
        
        print("✅ executeManual() erfolgreich abgeschlossen")
        
        return savedAppointment
    }
    
    // ✅ Für Email-Import
    @discardableResult
    func execute(_ appointment: Appointment) async throws -> Appointment {
        print("\n💾 === ADD APPOINTMENT USE CASE ===")
        print("📅 Termin: \(appointment.therapist) am \(appointment.date)")
        
        // ✅ Validation
        guard !appointment.therapist.isEmpty else {
            print("❌ Therapeut leer")
            throw ValidationError.emptyTherapistName
        }
        
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
            therapist: appointment.therapist
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

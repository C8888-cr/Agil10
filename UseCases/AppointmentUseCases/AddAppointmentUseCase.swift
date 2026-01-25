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
       private let authService: AuthService  // ← INJEKTED!
       
       init(repository: AppointmentRepository, authService: AuthService) {
           self.repository = repository
           self.authService = authService
       }
    
    
    // ✅ NEU: Sheet-Input (Parameter)
       func executeManual(
           date: Date,
           therapist: String,
           locationName: String? = nil,
           locationAddress: String? = nil,
           latitude: Double? = nil,
           longitude: Double? = nil,
           notes: String? = nil
       ) async throws {
           guard let user = await authService.currentUser else {
               print("❌ Kein User gefunden")
               throw AppointmentError.validationFailed("")
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
               userId: user.id,
               praxisId: UUID()
           )
           print("📅 Appointment erstellt:")
           print("   → Datum: \(date)")
           print("   → Therapeut: \(therapist)")
           print("   → User: \(user.id)")
           
           try await execute(appointment)  // Deine bestehende Validierung!
           
           print("✅ executeManual() erfolgreich abgeschlossen")
       }
    
    
    
    
    func execute(_ appointment: Appointment) async throws {

        // Validation
        guard !appointment.therapist.isEmpty else {
            print("❌ Therapeut leer")
            throw ValidationError.emptyTherapistName
        }
        
        guard appointment.date > Date() else {
            print("❌ Datum in Vergangenheit: \(appointment.date)")
            throw ValidationError.invalidDateRange
        }
        print("✅ Validierung erfolgreich")
        
        
        // Duplikat-Check
        print("🔍 Prüfe Duplikate...")
        let isDuplicate = try await repository.checkDuplicate(
            date: appointment.date,
            therapist: appointment.therapist
           
        )
        
        guard !isDuplicate else {
            throw AppointmentError.duplicateAppointment
        }
        
        // Speichern
        print("💾 Speichere in Repository...")
        do {
            try await repository.save(appointment)
            print("✅ Repository.save() erfolgreich")
        } catch {
            print("❌ Repository.save() fehlgeschlagen: \(error)")
            throw AppointmentError.saveFailed(error.localizedDescription)
        }
    }
}

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
           date: Date, therapist: String,
           locationName: String? = nil, locationAddress: String? = nil,
           latitude: Double? = nil, longitude: Double? = nil, notes: String? = nil
       ) async throws {
           guard let user = await authService.currentUser else {
               throw AppointmentError.validationFailed("")
           }
           
           let appointment = Appointment(
               date: date, therapist: therapist,
               locationName: locationName, locationAddress: locationAddress,
               locationLatitude: latitude, locationLongitude: longitude,
               notes: notes,
               userId: user.id, praxisId: UUID()
           )
           
           try await execute(appointment)  // Deine bestehende Validierung!
       }
    
    
    
    
    func execute(_ appointment: Appointment) async throws {

        // Validation
        guard !appointment.therapist.isEmpty else {
            throw ValidationError.emptyTherapistName
        }
        
        guard appointment.date > Date() else {
            throw ValidationError.invalidDateRange
        }
        
        // Duplikat-Check
        let isDuplicate = try await repository.checkDuplicate(
            date: appointment.date,
            therapist: appointment.therapist
           
        )
        
        guard !isDuplicate else {
            throw AppointmentError.duplicateAppointment
        }
        
        // Speichern
        do {
            try await repository.save(appointment)
        } catch {
            throw AppointmentError.saveFailed(error.localizedDescription)  
        }
    }
}

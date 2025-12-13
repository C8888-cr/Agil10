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
    
    init(repository: AppointmentRepository) {
        self.repository = repository
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
        let isDuplicate = try repository.checkDuplicate(
            date: appointment.date,
            therapist: appointment.therapist
        )
        
        guard !isDuplicate else {
            throw AppointmentError.duplicateAppointment
        }
        
        // Speichern
        do {
            try repository.save(appointment)
        } catch {
            throw AppointmentError.saveFailed(error.localizedDescription)  
        }
    }
}

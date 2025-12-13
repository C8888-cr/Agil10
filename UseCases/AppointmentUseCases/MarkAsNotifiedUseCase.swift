//
//  MarkAsNotifiedUseCase.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  MarkAsNotifiedUseCase.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.10.25.
//

// Features/Appointments/UseCases/MarkAsNotifiedUseCase.swift
import Foundation
struct MarkAsNotifiedUseCase {
    private let repository: AppointmentRepository
    
    init(repository: AppointmentRepository) {
        self.repository = repository
    }
    
    func execute(_ appointment: Appointment) async throws {
        appointment.wasNotified = true
        appointment.isHighlighted = false
        try repository.save(appointment)
    }
}

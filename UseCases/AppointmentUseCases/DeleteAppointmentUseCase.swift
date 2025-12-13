//
//  DeleteAppointmentUseCase.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  DeleteAppointmentUseCase.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.10.25.
//

// Features/Appointments/UseCases/DeleteAppointmentUseCase.swift
import Foundation
struct DeleteAppointmentUseCase {
    private let repository: AppointmentRepository
    
    init(repository: AppointmentRepository) {
        self.repository = repository
    }
    
    func execute(_ appointment: Appointment) async throws {
        try repository.delete(appointment)
    }
}

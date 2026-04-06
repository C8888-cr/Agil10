//
//  loadAppointmentsUseCase.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//

import Foundation

class LoadAppointmentsUseCase: LoadAppointmentsUseCaseProtocol {
    private let repository: AppointmentRepository
    
    init(repository: AppointmentRepository) {
        self.repository = repository
    }
    
    func execute(for user: User) async throws -> [Appointment] {
           print("🔄 LoadAppointmentsUseCase für User: \(user.id)")
           
           let appointments = try await repository.fetchAll()
           
           print("✅ \(appointments.count) Appointments geladen")
           
           return appointments
       }
   }

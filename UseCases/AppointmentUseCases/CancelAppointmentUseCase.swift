//
//  CancelAppointmentUseCase.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  CancelAppointmentUseCase.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.10.25.
//
//TODO: popup mit 24 std case einbauen

// Features/Appointments/UseCases/CancelAppointmentUseCase.swift
import Foundation
struct CancelAppointmentUseCase {
    private let repository: AppointmentRepository
    private let emailService: EmailService
    
    init(
        repository: AppointmentRepository,
        emailService: EmailService
    ) {
        self.repository = repository
        self.emailService = emailService
    }
    
    func execute(
        appointment: Appointment,
        reason: String?,
        userEmail: String
    ) async throws {
        print("🚫 Setze Status auf cancelled für: \(appointment.therapist)")
        // ✅ User Praxis laden
        let practiceEmail = "praxis@physio-agil.de"
        
        
        // Status ändern
        appointment.status = .cancelled
        try await repository.save(appointment)
        print("✅ Status gesetzt: \(appointment.status)")
        

    }



    
    
    private func buildCancellationEmail(
        appointment: Appointment,
        reason: String?,
        userEmail: String
    ) -> (subject: String, body: String) {
        let subject = "Terminabsage - \(appointment.dateString)"
        
        var body = """
        Sehr geehrte Damen und Herren,
        
        hiermit möchte ich meinen Termin absagen:
        
        Datum: \(appointment.dateString)
        Uhrzeit: \(appointment.timeString)
        Therapeut: \(appointment.therapist)
        """
        
        if let reason = reason, !reason.isEmpty {
            body += "\n\nGrund: \(reason)"
        }
        
        body += """
        
        
        Mit freundlichen Grüßen
        \(userEmail)
        """
        
        return (subject, body)
    }
}

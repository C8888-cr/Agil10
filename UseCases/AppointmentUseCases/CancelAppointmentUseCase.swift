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
        userEmail: String,

    ) async throws {
        // Practice Email holen (später aus User/Practice Relationship)
           let practiceEmail = appointment.user?.practice?.email ?? "praxis@example.com"
        // Status ändern
        appointment.status = .cancelled
        try repository.save(appointment)
        
        // Email senden
        let emailContent = buildCancellationEmail(
            appointment: appointment,
            reason: reason,
            userEmail: userEmail
        )
        
        emailService.sendEmail(
            to: practiceEmail,
            subject: emailContent.subject,
            body: emailContent.body
        )
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

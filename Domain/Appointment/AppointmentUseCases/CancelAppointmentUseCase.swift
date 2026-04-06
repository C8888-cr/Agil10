
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
        userName: String, 
        practiceEmail: String
    ) async throws {
        print("🚫 Setze Status auf cancelled für: \(appointment.therapist)")
        
        // Status ändern
        appointment.status = .cancelled
        try await repository.save(appointment)
        print("✅ Status gesetzt: \(appointment.status)")
        

    }



    
    
    private func buildCancellationEmail(
        appointment: Appointment,
        reason: String?,
        userEmail: String,
        userName: String
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
        \(userName)
        """
        
        return (subject, body)
    }
}

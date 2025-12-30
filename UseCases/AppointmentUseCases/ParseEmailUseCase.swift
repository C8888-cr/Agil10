//
//  ParseEmailUseCase.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  ParseEmailUseCase.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.10.25.
//

// Features/Appointments/UseCases/ParseEmailUseCase.swift
import Foundation
struct ParseEmailUseCase {
    private let parser: EmailParserService
    
    init(parser: EmailParserService) {
        self.parser = parser
    }
    
    func execute(_ emailText: String) async throws -> [Appointment] {
        guard !emailText.isEmpty else {
            throw AppointmentError.parsingFailed("Email text is empty")
        }
        
        let appointments = await parser.parseAppointments(from: emailText)
        
        guard !appointments.isEmpty else {
            throw AppointmentError.parsingFailed("No appointments found in email")
        }
        
        return appointments
    }
}

//
//  ParseAppointmentsFromEmail.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//

import Foundation
import SwiftData

class ParseAppointmentsFromEmailUseCase: ParseAppointmentsFromEmailUseCaseProtocol {
    
    // MARK: - Dependencies
    private let repository: AppointmentRepository
    private let emailParser: EmailParserService
    private let detectChangesUseCase: DetectAppointmentChangesUseCase
    
    // MARK: - Init
    init(
        repository: AppointmentRepository,
        emailParser: EmailParserService,
        detectChangesUseCase: DetectAppointmentChangesUseCase
    ) {
        self.repository = repository
        self.emailParser = emailParser
        self.detectChangesUseCase = detectChangesUseCase
    }
    
    // MARK: - Execute
    func execute(emailText: String) async throws -> AppointmentChanges {
        // 1️⃣ Email hashen (für Duplikat-Erkennung)
        let emailHash = emailText.hashValue.description
        
        // 2️⃣ Email parsen
        let parsedAppointments = await emailParser.parseAppointments(from: emailText)
        
        // 3️⃣ Existierende Termine laden
        let existingAppointments = try repository.fetchAll()
        
        // 4️⃣ Änderungen erkennen
        let changes = detectChangesUseCase.execute(
            parsedAppointments: parsedAppointments,
            emailHash: emailHash,
            existingAppointments: existingAppointments
        )
        
        // 5️⃣ Neue Termine speichern
        for appointment in changes.added {
            try repository.save(appointment)
        }
        
        // 6️⃣ Geänderte und abgesagte speichern
        for appointment in changes.modified + changes.cancelled {
            try repository.save(appointment)
        }
        
        print("✅ Email import completed: \(changes.added.count) added, \(changes.modified.count) modified, \(changes.cancelled.count) cancelled")
        
        return changes
    }
}

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
        private let session: SessionManager
        private let addAppointmentUseCase: AddAppointmentUseCase
        
        // MARK: - Init
        init(
            repository: AppointmentRepository,
            emailParser: EmailParserService,
            detectChangesUseCase: DetectAppointmentChangesUseCase,
            session: SessionManager,
            addAppointmentUseCase: AddAppointmentUseCase
        ) {
            self.repository = repository
            self.emailParser = emailParser
            self.detectChangesUseCase = detectChangesUseCase
            self.session = session
            self.addAppointmentUseCase = addAppointmentUseCase
        }
    
    // MARK: - Execute
    func execute(emailText: String) async throws -> AppointmentChanges {
        // 1️⃣ Email hashen (für Duplikat-Erkennung)
        let emailHash = emailText.hashValue.description
        
        // 2️⃣ Email parsen
        let parsedAppointments = await emailParser.parseAppointments(from: emailText)
        
        // 3️⃣ Existierende Termine laden
        let existingAppointments = try await repository.fetchAll()
        
        // 4️⃣ Änderungen erkennen
        var changes = detectChangesUseCase.execute(
            parsedAppointments: parsedAppointments,
            emailHash: emailHash,
            existingAppointments: existingAppointments
        )
        
        // 5️⃣ Neue Termine über AddAppointmentUseCase anlegen
                //    (legt zusätzlich den Apple-Kalender-Event an → sichtbar in Agil & Apple).
                //    userId muss VOR dem Anlegen gesetzt sein (AddAppointmentUseCase
                //    greift mit force-unwrap auf userId zu).
                //    Fehler pro Termin werden gesammelt, der Import läuft weiter.
                let userId = await MainActor.run { session.currentUser?.id }
                var stillAdded: [Appointment] = []
                for appointment in changes.added {
                    appointment.userId = userId
                    do {
                        try await addAppointmentUseCase.execute(appointment)
                        stillAdded.append(appointment)
                    } catch {
                        print("⚠️ Termin konnte nicht angelegt werden: \(error)")
                        changes.failed.append(appointment)
                    }
                }
                changes.added = stillAdded
        
        // 6️⃣ Geänderte und abgesagte speichern
        for appointment in changes.modified + changes.cancelled {
            try await repository.save(appointment)
        }
        
        print("✅ Email import completed: \(changes.added.count) added, \(changes.modified.count) modified, \(changes.cancelled.count) cancelled")
        
        return changes
    }
}

//
//  ParseAppointmentsFromICSUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 24.05.26.
//


//
//  ParseAppointmentsFromICSUseCase.swift
//  Agil10.0
//
//  Gegenstück zu ParseAppointmentsFromEmailUseCase – nur die Quelle ist
//  eine .ics-Datei statt eines Email-Textes. Ab dem DetectChanges-Schritt
//  ist die Verarbeitung identisch, sodass der ICS-Import durch dasselbe
//  ImportResultsView-Sheet läuft wie der Email-Import.
//
//  Unterschied zum Email-UseCase: DetectChanges wird mit matchByUID = true
//  aufgerufen. Eine Terminverschiebung behält in der ICS ihre UID und wird
//  dadurch als "geändert" erkannt – nicht als abgesagt + neu.
//

import Foundation
import SwiftData

class ParseAppointmentsFromICSUseCase {

    // MARK: - Fehler

    /// Datei gelesen, aber das SUMMARY enthält das Agil-Kennzeichen nicht.
    /// Die UI kann darauf reagieren (z.B. Warnhinweis), statt hart zu blocken.
    enum ICSImportError: LocalizedError {
        case notAnAgilFile

        var errorDescription: String? {
            switch self {
            case .notAnAgilFile:
                return "Diese Datei scheint nicht von Praxis agil zu stammen."
            }
        }
    }

    // MARK: - Dependencies

    private let repository: AppointmentRepository
    private let icsParser: ICSParserService
    private let detectChangesUseCase: DetectAppointmentChangesUseCase
    private let session: SessionManager
    private let addAppointmentUseCase: AddAppointmentUseCase
    private let updateAppointmentUseCase: UpdateAppointmentUseCase

    // MARK: - Init

    init(
        repository: AppointmentRepository,
        icsParser: ICSParserService,
        detectChangesUseCase: DetectAppointmentChangesUseCase,
        session: SessionManager,
        addAppointmentUseCase: AddAppointmentUseCase,
        updateAppointmentUseCase: UpdateAppointmentUseCase
    ) {
        self.repository = repository
        self.icsParser = icsParser
        self.detectChangesUseCase = detectChangesUseCase
        self.session = session
        self.addAppointmentUseCase = addAppointmentUseCase
        self.updateAppointmentUseCase = updateAppointmentUseCase
    }

    // MARK: - Execute

    /// Parst eine .ics-Datei und verarbeitet die erkannten Änderungen.
    /// - Parameters:
    ///   - icsText: Roher Inhalt der .ics-Datei.
    ///   -
    /// - Returns: Erkannte Änderungen (added / modified / cancelled).
    func execute(icsText: String) async throws -> AppointmentChanges {

        // 1️⃣ ICS parsen
        let parseResult = await icsParser.parseAppointments(from: icsText)

        // 2️⃣ Herkunfts-Check – fremde Datei nur mit ausdrücklichem OK importieren
        guard parseResult.looksLikeAgil
        else {
            throw ICSImportError.notAnAgilFile
        }
        let parsedAppointments = parseResult.appointments

        // 3️⃣ Existierende Termine laden
        let existingAppointments = try await repository.fetchAll()

        // 4️⃣ Änderungen erkennen – matchByUID: true nutzt die stabile ICS-UID.
        //    emailHash wird im UID-Modus nicht auf die Termine geschrieben
        //    (siehe DetectAppointmentChangesUseCase), daher leerer Platzhalter.
        var changes = detectChangesUseCase.execute(
            parsedAppointments: parsedAppointments,
            emailHash: "",
            existingAppointments: existingAppointments,
            matchByUID: true
        )

        // 5️⃣ Neue Termine anlegen (inkl. Apple-Kalender-Event).
        //    userId muss vor dem Anlegen gesetzt sein. Fehler pro Termin
        //    werden gesammelt, der Import läuft weiter.
        let userId = await MainActor.run { session.currentUser?.id }
        var stillAdded: [Appointment] = []
        for appointment in changes.added {
            appointment.userId = userId
            do {
                try await addAppointmentUseCase.execute(appointment)
                stillAdded.append(appointment)
            } catch {
                print("⚠️ ICS-Termin konnte nicht angelegt werden: \(error)")
                changes.failed.append(appointment)
            }
        }
        changes.added = stillAdded

        // 6️⃣ Geänderte Termine aktualisieren (inkl. Apple-Kalender-Event).
        //    Werte kommen aus dem Objekt – der Detektor hat sie schon gesetzt.
        for appointment in changes.modified {
            do {
                _ = try await updateAppointmentUseCase.execute(
                    appointment,
                    newDate: appointment.date,
                    newTherapist: appointment.therapist,
                    newLocationName: appointment.locationName,
                    newLocationAddress: appointment.locationAddress,
                    newLatitude: appointment.locationLatitude,
                    newLongitude: appointment.locationLongitude,
                    newNotes: appointment.notes,
                    newDurationMinutes: appointment.durationMinutes
                )
            } catch {
                print("⚠️ Geänderter ICS-Termin konnte nicht aktualisiert werden: \(error)")
            }
        }

        // 6b️⃣ Abgesagte Termine: vorerst nur speichern. Die endgültige
        //     Entscheidung (behalten / löschen) trifft der User im Sheet,
        //     ausgeführt wird sie danach in AppointmentViewModel.
        for appointment in changes.cancelled {
            try await repository.save(appointment)
        }

        print("✅ ICS import completed: \(changes.added.count) added, \(changes.modified.count) modified, \(changes.cancelled.count) cancelled")

        return changes
    }
}

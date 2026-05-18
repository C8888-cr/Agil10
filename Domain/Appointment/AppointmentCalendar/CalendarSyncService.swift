//
//  CalendarSyncService.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


//
//  CalendarSyncService.swift
//  Agil10.0
//
//  Plattformneutrale Schnittstelle zum Geräte-Kalender.
//  iOS: EventKit. Android (später): CalendarContract.
//

import Foundation

public protocol CalendarSyncService {

    /// Aktueller Permission-Status (synchron lesbar).
    var authorizationStatus: CalendarAuthorizationStatus { get }

    /// Fragt User um Erlaubnis (zeigt iOS-Dialog).
    /// Wirft, wenn der User ablehnt.
    func requestAccess() async throws

    /// Lädt alle Events im angegebenen Zeitraum (alle Kalender, alle Quellen).
    func getEvents(from start: Date, to end: Date) async throws -> [CalendarEvent]

    /// Erstellt einen neuen Event und gibt die EventKit-ID zurück.
    /// Diese ID speichern wir am Appointment, um später Updates/Deletes zu machen.
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String?
    ) async throws -> String   // Event-Identifier

    /// Aktualisiert einen bestehenden Event.
    func updateEvent(
        identifier: String,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String?
    ) async throws

    /// Löscht einen Event aus dem Kalender.
    /// Wirft NICHT, wenn der Event nicht mehr existiert (User hat ihn evtl. selbst gelöscht).
    func deleteEvent(identifier: String) async throws
    
    
    /// Beobachtet externe Änderungen am Kalender (z.B. wenn der User
    /// in Apple-Kalender einen Termin direkt ändert).
    /// Der Callback wird aufgerufen, sobald sich was geändert hat.
    /// Wichtig: Der Callback läuft auf einem Background-Thread!
    func startObservingChanges(onChange: @escaping () async -> Void)

    /// Stoppt das Beobachten (z.B. wenn ViewModel deinitialisiert wird)
    func stopObservingChanges()
    
}

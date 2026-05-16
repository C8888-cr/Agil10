//
//  GetCalendarEventsUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


//
//  GetCalendarEventsUseCase.swift
//  Agil10.0
//
//  Plattformneutral. Holt Kalender-Events für die Anzeige.
//

import Foundation

public final class GetCalendarEventsUseCase {

    private let calendarSync: CalendarSyncService

    public init(calendarSync: CalendarSyncService) {
        self.calendarSync = calendarSync
    }

    public func execute(from start: Date, to end: Date) async throws -> [CalendarEvent] {
        switch calendarSync.authorizationStatus {
        case .notDetermined:
            try await calendarSync.requestAccess()
        case .denied:
            throw CalendarSyncError.accessDenied
        case .restricted:
            throw CalendarSyncError.accessRestricted
        case .authorized:
            break
        }

        return try await calendarSync.getEvents(from: start, to: end)
    }
}
//
//  AppointmentPlannerViewModel.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


//
//  AppointmentPlannerViewModel.swift
//  Agil10.0
//
//  Lädt Kalender-Events und Agil-Termine, kombiniert sie für die Anzeige.
//

import Foundation
import SwiftData

@MainActor
final class AppointmentPlannerViewModel: ObservableObject {

    @Published var events: [CalendarEvent] = []
    @Published var isLoading: Bool = false
    @Published var permissionState: PermissionState = .unknown
    @Published var errorMessage: String?

    enum PermissionState {
        case unknown          // App weiß noch nichts
        case needsOnboarding  // notDetermined → erst Erklärungs-Karte zeigen
        case authorized       // alles gut, Daten laden
        case denied           // User hat Nein gesagt → Fallback-Modus
        case restricted       // System-Verbot
    }

    private let getEvents: GetCalendarEventsUseCase
    private let calendarSync: CalendarSyncService

    init(calendarSync: CalendarSyncService) {
        self.calendarSync = calendarSync
        self.getEvents = GetCalendarEventsUseCase(calendarSync: calendarSync)
        self.refreshPermissionState()
    }

    // MARK: - Permission

    func refreshPermissionState() {
        switch calendarSync.authorizationStatus {
        case .notDetermined:
            permissionState = .needsOnboarding
        case .authorized:
            permissionState = .authorized
        case .denied:
            permissionState = .denied
        case .restricted:
            permissionState = .restricted
        }
    }

    func requestAccess() async {
        do {
            try await calendarSync.requestAccess()
            permissionState = .authorized
        } catch CalendarSyncError.accessDenied {
            permissionState = .denied
        } catch {
            errorMessage = error.localizedDescription
            permissionState = .denied
        }
    }

    func skipOnboarding() {
        // User will ohne Kalender → Fallback-Modus.
        // Status bleibt .needsOnboarding, aber wir merken uns "skipped"
        permissionState = .denied
    }

    // MARK: - Data Loading

    func loadEvents(from start: Date, to end: Date) async {
        guard permissionState == .authorized else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            events = try await getEvents.execute(from: start, to: end)
        } catch {
            errorMessage = error.localizedDescription
            events = []
        }
    }

    // MARK: - Helper für Tagesansicht

    /// Alle Events, die an einem bestimmten Tag stattfinden.
    func events(on day: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.start, inSameDayAs: day) ||
            calendar.isDate(event.end, inSameDayAs: day) ||
            (event.start < calendar.startOfDay(for: day) && event.end > calendar.startOfDay(for: day))
        }
    }

    /// Tage im angezeigten Monat, an denen Events liegen (für Marker-Punkte).
    func daysWithEvents(in month: Date) -> Set<Date> {
        let calendar = Calendar.current
        var result = Set<Date>()
        for event in events {
            let day = calendar.startOfDay(for: event.start)
            result.insert(day)
        }
        return result
    }
}
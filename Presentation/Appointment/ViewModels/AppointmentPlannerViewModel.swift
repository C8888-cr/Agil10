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

    /// Cache: Welche Monatsanker wurden bereits geladen?
    private var loadedMonths: Set<Date> = []

    /// Vorberechneter Index: Welche Tage haben Events?
    /// Wird einmal nach jedem Load gefüllt – O(1) Lookup statt O(n) Filter.
    @Published private(set) var daysWithEventsIndex: Set<Date> = []

    enum PermissionState {
        case unknown
        case needsOnboarding
        case authorized
        case denied
        case restricted
    }

    private let getEvents: GetCalendarEventsUseCase
    private let calendarSync: CalendarSyncService

    init(calendarSync: CalendarSyncService) {
        self.calendarSync = calendarSync
        self.getEvents = GetCalendarEventsUseCase(calendarSync: calendarSync)
        self.refreshPermissionState()
        observeAppointmentChanges()
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
        permissionState = .denied
    }

    // MARK: - Data Loading

    func loadEvents(from start: Date, to end: Date) async {
        guard permissionState == .authorized else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let newEvents = try await getEvents.execute(from: start, to: end)
            var byId = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
            for ev in newEvents { byId[ev.id] = ev }
            events = Array(byId.values)
            rebuildDaysWithEventsIndex()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Lädt einen Monat ± 2 (also 5 Monate), wenn der Anker-Monat noch nicht im Cache ist.
    /// Events werden zum bestehenden Array hinzugefügt (deduped), nicht ersetzt.
    func loadEventsIfNeeded(around monthAnchor: Date) async {
        guard permissionState == .authorized else { return }

        let cal = Calendar.current
        let anchor = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor)) ?? monthAnchor

        guard !loadedMonths.contains(anchor) else { return }

        guard let start = cal.date(byAdding: .month, value: -2, to: anchor),
              let end = cal.date(byAdding: .month, value: 3, to: anchor) else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let newEvents = try await getEvents.execute(from: start, to: end)

            var byId = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
            for ev in newEvents { byId[ev.id] = ev }
            events = Array(byId.values)

            rebuildDaysWithEventsIndex()

            for offset in -2...2 {
                if let m = cal.date(byAdding: .month, value: offset, to: anchor) {
                    let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: m)) ?? m
                    loadedMonths.insert(monthStart)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Invalidiert gezielt einen Monat und lädt ihn neu.
    /// Wird aufgerufen nachdem ein Termin gespeichert/geändert/gelöscht wurde.
    func refreshMonth(containing date: Date) async {
        let cal = Calendar.current
        let anchor = cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date

        // Cache des 5-Monats-Fensters invalidieren (loadEventsIfNeeded lädt -2…+2 Monate)
        for offset in -2...2 {
            if let m = cal.date(byAdding: .month, value: offset, to: anchor) {
                let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: m)) ?? m
                loadedMonths.remove(monthStart)
            }
        }

        // Events im betroffenen Fenster aus dem Array entfernen,
        // damit gelöschte Events nicht im Merge-Cache zurückbleiben.
        guard let windowStart = cal.date(byAdding: .month, value: -2, to: anchor),
              let windowEnd = cal.date(byAdding: .month, value: 3, to: anchor) else {
            await loadEventsIfNeeded(around: date)
            return
        }
        events.removeAll { event in
            event.start < windowEnd && event.end >= windowStart
        }
        rebuildDaysWithEventsIndex()

        await loadEventsIfNeeded(around: date)
    }
    
    
    /// Cache leeren – z. B. bei externem Calendar-Change.
    func invalidateCache() {
        loadedMonths.removeAll()
        events = []
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

    // MARK: - External Change Observation

        /// Lauscht auf Appointment-Änderungen aus anderen ViewModels (z.B. Card-Delete).
        /// Sorgt dafür, dass alle Views, die plannerVM.events anzeigen, frisch bleiben.
        private func observeAppointmentChanges() {
            NotificationCenter.default.addObserver(
                forName: .appointmentsChanged,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                let affectedDate = notification.userInfo?["date"] as? Date ?? Date()
                Task { @MainActor [weak self] in
                    await self?.refreshMonth(containing: affectedDate)
                }
            }
        }

    
    /// Baut den Tages-Index neu auf. O(n) einmalig, statt bei jedem View-Render.
    private func rebuildDaysWithEventsIndex() {
        let cal = Calendar.current
        var days = Set<Date>()
        for event in events {
            var day = cal.startOfDay(for: event.start)
            let lastDay = cal.startOfDay(for: event.end)
            while day <= lastDay {
                days.insert(day)
                guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
        }
        daysWithEventsIndex = days
    }
}

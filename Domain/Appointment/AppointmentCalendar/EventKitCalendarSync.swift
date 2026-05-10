//
//  EventKitCalendarSync.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


//
//  EventKitCalendarSync.swift
//  Agil10.0
//
//  iOS-spezifische Umsetzung von CalendarSyncService via EventKit.
//

import Foundation
import EventKit
import UIKit

public final class EventKitCalendarSync: CalendarSyncService {

    private let eventStore: EKEventStore

    public init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    // MARK: - Authorization

    public var authorizationStatus: CalendarAuthorizationStatus {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorized, .fullAccess, .writeOnly:
            return .authorized
        @unknown default:
            return .denied
        }
    }

    public func requestAccess() async throws {
        if #available(iOS 17.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                if !granted {
                    throw CalendarSyncError.accessDenied
                }
            } catch let error as CalendarSyncError {
                throw error
            } catch {
                throw CalendarSyncError.underlyingError(error)
            }
        } else {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        cont.resume(throwing: CalendarSyncError.underlyingError(error))
                    } else if !granted {
                        cont.resume(throwing: CalendarSyncError.accessDenied)
                    } else {
                        cont.resume()
                    }
                }
            }
        }
    }

    // MARK: - Read

    public func getEvents(from start: Date, to end: Date) async throws -> [CalendarEvent] {
        guard authorizationStatus == .authorized else {
            throw CalendarSyncError.accessDenied
        }

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil   // alle Kalender (iCloud, Google, Outlook etc.)
        )

        let ekEvents = eventStore.events(matching: predicate)

        return ekEvents.map { event in
            CalendarEvent(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Ohne Titel",
                start: event.startDate,
                end: event.endDate,
                isAllDay: event.isAllDay,
                calendarColor: Self.color(from: event.calendar),
                source: event.calendar?.source.title ?? "Lokal"
            )
        }
    }

    // MARK: - Write

    public func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String?
    ) async throws -> String {
        guard authorizationStatus == .authorized else {
            throw CalendarSyncError.accessDenied
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw CalendarSyncError.underlyingError(error)
        }

        guard let identifier = event.eventIdentifier else {
            throw CalendarSyncError.underlyingError(
                NSError(domain: "EventKitCalendarSync", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Event ohne Identifier gespeichert"])
            )
        }

        return identifier
    }

    public func updateEvent(
        identifier: String,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String?
    ) async throws {
        guard authorizationStatus == .authorized else {
            throw CalendarSyncError.accessDenied
        }

        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw CalendarSyncError.eventNotFound(identifier)
        }

        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.notes = notes

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw CalendarSyncError.underlyingError(error)
        }
    }

    public func deleteEvent(identifier: String) async throws {
        guard authorizationStatus == .authorized else {
            throw CalendarSyncError.accessDenied
        }

        // Event nicht mehr da → ignorieren (nicht als Fehler werten,
        // User hat ihn evtl. direkt im Apple-Kalender gelöscht)
        guard let event = eventStore.event(withIdentifier: identifier) else {
            print("ℹ️ Event \(identifier) bereits gelöscht – ignoriere")
            return
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            throw CalendarSyncError.underlyingError(error)
        }
    }

    // MARK: - Helpers

    private static func color(from calendar: EKCalendar?) -> CalendarEventColor {
        guard let cgColor = calendar?.cgColor else {
            return .defaultGray
        }
        let uiColor = UIColor(cgColor: cgColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return CalendarEventColor(red: Double(r), green: Double(g), blue: Double(b))
    }
}
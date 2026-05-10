//
//  CalendarEvent.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


//
//  CalendarEvent.swift
//  Agil10.0
//
//  Domain-Modell für Termine aus dem Geräte-Kalender.
//  Plattformneutral: Auf iOS via EventKit, später Android via CalendarContract.
//

import Foundation

/// Ein Event aus dem Geräte-Kalender (iPhone-Kalender).
///
/// Wir lesen NUR die Felder, die wir zum Anzeigen brauchen.
/// Keine Teilnehmer, keine Notizen, keine Anhänge → Datensparsamkeit.
public struct CalendarEvent: Identifiable, Equatable, Hashable {
    public let id: String          // EventKit-Identifier
    public let title: String       // "Zahnarzt", "Mama anrufen" etc.
    public let start: Date
    public let end: Date
    public let isAllDay: Bool
    public let calendarColor: CalendarEventColor   // Farbe des Quell-Kalenders
    public let source: String      // z.B. "iCloud", "Google", "Privat"

    public init(
        id: String,
        title: String,
        start: Date,
        end: Date,
        isAllDay: Bool,
        calendarColor: CalendarEventColor,
        source: String
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.calendarColor = calendarColor
        self.source = source
    }
}

/// Plattformneutrale Farbe des Quell-Kalenders.
/// iOS liefert UIColor → wir mappen auf RGB.
public struct CalendarEventColor: Equatable, Hashable {
    public let red: Double      // 0.0 – 1.0
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public static let defaultGray = CalendarEventColor(red: 0.5, green: 0.5, blue: 0.5)
}
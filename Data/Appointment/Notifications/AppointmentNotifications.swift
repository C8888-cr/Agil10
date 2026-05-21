
//  AppointmentNotifications.swift
//  Agil
//
//  Zentrale Notification-Namen für Appointment-Änderungen.
//  Wird gepostet, wenn ein Termin hinzugefügt, geändert oder gelöscht wurde,
//  damit andere ViewModels (z.B. AppointmentPlannerViewModel) ihren Cache invalidieren können.
//

import Foundation

extension Notification.Name {
    /// Wird gepostet, wenn sich Appointments geändert haben (add/update/delete).
    /// userInfo["date"]: Date? – betroffenes Datum, um gezielt einen Monat zu refreshen.
    static let appointmentsChanged = Notification.Name("agil.appointmentsChanged")
}

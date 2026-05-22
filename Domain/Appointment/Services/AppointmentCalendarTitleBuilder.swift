//
//  AppointmentCalendarTitleBuilder.swift
//  Agil10.0
//
//  Created by Christiane Roth on 21.05.26.
//


import Foundation

/// Baut den Titel für den Apple-Kalender-Event aus einem Appointment.
/// Zentrale Stelle, damit Add/Update/Email-Import konsistent bleiben.
enum AppointmentCalendarTitleBuilder {
    
    private static let baseLabel = "Physio agil"
    
    static func build(therapist: String?, notes: String?) -> String {
        let base: String
        if let therapist, !therapist.isEmpty {
            base = "\(baseLabel): \(therapist)"
        } else {
            base = baseLabel
        }
        
        if let notes, !notes.isEmpty {
            return "\(base) – \(notes)"
        }
        return base
    }
    
    //// Titel anhand des Appointment-Status – bei .cancelled wird "Abgesagt"
    /// gesetzt, Therapeut & Notizen entfallen dann bewusst.
    static func build(for appointment: Appointment) -> String {
        if appointment.status == .cancelled {
            return "\(baseLabel): Abgesagt"
        }
        return build(therapist: appointment.therapist, notes: appointment.notes)
    }
}

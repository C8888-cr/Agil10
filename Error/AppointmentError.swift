//
//  AppointmentError.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  AppointmentError.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.10.25.
//

// Features/Appointments/Domain/Errors/AppointmentError.swift
import Foundation
enum AppointmentError: LocalizedError {
    case duplicateAppointment
    case invalidDate
    case parsingFailed(String)  // ← Mit Details
      case saveFailed(String)
      case deleteFailed(String)
    case notFound
    case emailSendFailed
    case validationFailed(String)
    
    
    var errorDescription: String? {
        switch self {
        case .duplicateAppointment:
            return "Dieser Termin existiert bereits"
        case .invalidDate:
            return "Ungültiges Datum"
        case .parsingFailed(let message):
            return "Email konnte nicht verarbeitet werden: \(message)"
        case .saveFailed(let message):
            return "Termin konnte nicht gespeichert werden: \(message)"
        case .deleteFailed(let message):  // ← FIX!
      
            return "Termin konnte nicht gelöscht werden: \(message)"
        case .notFound:
            return "Termin wurde nicht gefunden"
        case .emailSendFailed:
            return "Email konnte nicht versendet werden"
        case .validationFailed(let message):  // ← FIX!
                  return "Validierung fehlgeschlagen: \(message)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .duplicateAppointment:
            return "Ein Termin mit diesem Datum und Therapeuten existiert bereits."
        case .invalidDate:
            return "Das gewählte Datum liegt in der Vergangenheit oder ist ungültig."
        case .parsingFailed(let message):
            return "Die Email enthält keine gültigen Termindaten: \(message)"
        case .saveFailed(let message):
            return "Beim Speichern ist ein Datenbankfehler aufgetreten: \(message)"
        case .deleteFailed(let message):
            return "Beim Löschen ist ein Fehler aufgetreten: \(message)"
        case .notFound:
            return "Der gesuchte Termin konnte nicht gefunden werden."
        case .emailSendFailed:
            return "Die Email-App konnte nicht geöffnet werden."
        case .validationFailed(let details):
                   return "Die Eingabevalidierung ist fehlgeschlagen: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .duplicateAppointment:
            return "Bitte überprüfe deine bestehenden Termine."
        case .invalidDate:
            return "Wähle ein gültiges, zukünftiges Datum."
        case .parsingFailed:
            return "Stelle sicher, dass die Email Datum, Uhrzeit und Therapeut enthält."
        case .saveFailed, .deleteFailed:
            return "Bitte versuche es erneut oder starte die App neu."
        case .notFound:
            return "Der Termin wurde möglicherweise bereits gelöscht."
        case .emailSendFailed:
            return "Stelle sicher, dass eine Email-App installiert ist."
        case .validationFailed:
            return "Überprüfe deine Eingaben und versuche es erneut."
        }
    }
}

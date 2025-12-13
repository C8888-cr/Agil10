//
//  AuthError.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


//
//  AuthError.swift
//  Agil9.0
//
//  Created by Christiane Roth on 11.11.25.
//

// Domain/Errors/AuthError.swift
import Foundation
enum AuthError: LocalizedError, Identifiable {
    case invalidEmail
    case passwordTooShort
    case passwordsDoNotMatch
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case networkError(String)
    case keychainError
    case unknownError
    
    var id: String {
        errorDescription ?? "unknown_error"
    }
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Bitte gib eine gültige Email ein"
        case .passwordTooShort:
            return "Passwort muss mindestens 6 Zeichen lang sein"
        case .passwordsDoNotMatch:
            return "Passwörter stimmen nicht überein"
        case .invalidCredentials:
            return "Email oder Passwort sind falsch"
        case .userNotFound:
            return "Benutzer nicht gefunden"
        case .emailAlreadyExists:
            return "Diese Email existiert bereits"
        case .networkError(let message):
            return "Netzwerkfehler: \(message)"
        case .keychainError:
            return "Fehler beim Speichern der Anmeldedaten"
        case .unknownError:
            return "Ein unbekannter Fehler ist aufgetreten"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Überprüfe deine Email-Adresse"
        case .passwordTooShort:
            return "Nutze ein längeres Passwort"
        case .invalidCredentials:
            return "Überprüfe deine Anmeldedaten oder nutze 'Passwort vergessen'"
        default:
            return nil
        }
    }
}

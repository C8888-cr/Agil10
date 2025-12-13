//
//  ValidationError.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  ValidationError.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.10.25.
//

// Features/Appointments/Domain/Errors/ValidationError.swift
import Foundation
enum ValidationError: LocalizedError {
    case emptyTherapistName
    case invalidDateRange
    case notesExceedMaxLength(maxLength: Int)
    case invalidEmailFormat
    
    var errorDescription: String? {
        switch self {
        case .emptyTherapistName:
            return "Therapeutenname fehlt"
        case .invalidDateRange:
            return "Ungültiger Datumsbereich"
        case .notesExceedMaxLength(let maxLength):
            return "Notizen zu lang (max. \(maxLength) Zeichen)"
        case .invalidEmailFormat:
            return "Ungültiges Email-Format"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emptyTherapistName:
            return "Bitte gib einen Therapeutennamen ein."
        case .invalidDateRange:
            return "Das Datum muss in der Zukunft liegen."
        case .notesExceedMaxLength(let maxLength):
            return "Bitte kürze die Notizen auf \(maxLength) Zeichen."
        case .invalidEmailFormat:
            return "Bitte gib eine gültige Email-Adresse ein."
        }
    }
}

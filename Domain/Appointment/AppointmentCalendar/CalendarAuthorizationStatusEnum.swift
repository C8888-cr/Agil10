//
//  CalendarAuthorizationStatus.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


//
//  CalendarAuthorizationStatus.swift
//  Agil10.0
//
//  Plattformneutraler Permission-Status.
//

import Foundation

public enum CalendarAuthorizationStatus {
    case notDetermined   // User wurde noch nicht gefragt
    case authorized      // alles gut
    case denied          // User hat Nein gesagt
    case restricted      // System verbietet es (z.B. Kindersicherung)
}

public enum CalendarSyncError: Error, LocalizedError {
    case accessDenied
    case accessRestricted
    case eventNotFound(String)
    case underlyingError(Error)

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Zugriff auf den Kalender wurde nicht erlaubt."
        case .accessRestricted:
            return "Kalender-Zugriff ist auf diesem Gerät nicht verfügbar."
        case .eventNotFound(let id):
            return "Der Kalender-Eintrag wurde nicht gefunden (ID: \(id))."
        case .underlyingError(let err):
            return err.localizedDescription
        }
    }
}
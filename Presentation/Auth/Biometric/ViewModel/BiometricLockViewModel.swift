//
//  BiometricLockViewModel.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//
import SwiftUI
import SwiftData


@MainActor
final class BiometricLockViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isAuthenticating = false
    
    private let session: SessionManager
    
    init(session: SessionManager) {
        self.session = session
    }
    
    func unlock() async {
        print("🔐 BiometricLockViewModel.unlock() START")
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            print("🔐 Rufe session.unlockSession()...")
            try await session.unlockSession()
            print("✅ Unlock erfolgreich")
            errorMessage = nil
        } catch let error as BiometricAuthError {
            print("❌ Unlock fehlgeschlagen: \(error)")
            errorMessage = message(for: error)
        } catch {
            print("❌ Unbekannter Fehler: \(error)")
            errorMessage = "Unbekannter Fehler"
        }
    }
    
    private func message(for error: BiometricAuthError) -> String {
        switch error {
        case .notAvailable:       return "Biometrie nicht verfügbar."
        case .notEnrolled:        return "Bitte Face ID / Touch ID einrichten."
        case .userCancelled:      return "Authentifizierung abgebrochen."
        case .authenticationFailed: return "Authentifizierung fehlgeschlagen."
        case .lockout:            return "Zu viele Versuche. Mit Passwort anmelden."
        case .unknown:            return "Unbekannter Fehler."
        }
    }
}

//
//  KGGAuthViewModel.swift
//  Agil
//
//  Created by Christiane Roth on 28.06.26.
//
//  Login für Therapeuten-App: Praxis auswählen + Admin-Passwort eingeben
//  - UUID-basiert
//  - Passwort-Reset mit Reset-Code (z.B. "ResetPraxis1")
//  - Verschlüsselte Passwort-Verwaltung
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class KGGAuthViewModel: ObservableObject {
    
    // MARK: - Login State
    @Published var selectedPraxisId: UUID?
    @Published var passwordInput: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false
    @Published var currentCredentials: KGGLoginCredentials?
    
    // MARK: - Reset State
    @Published var showResetFlow = false
    @Published var resetCode: String = ""
    @Published var resetTempPassword: String?
    @Published var newPasswordInput: String = ""
    @Published var confirmPasswordInput: String = ""
    
    private let sessionManager = KGGSessionManager()
    private let dataManager = PraxisDataManager.shared
    
    // MARK: - Public API
    
    var allPraxen: [KGGPraxis] {
        getAllKGGPraxen()
    }
    
    var selectedPraxis: KGGPraxis? {
        guard let id = selectedPraxisId else { return nil }
        return getKGGPraxis(by: id)
    }
    
    // MARK: - Login
    
    func login(therapistName: String? = nil) {
        guard let praxisId = selectedPraxisId else {
            errorMessage = "Bitte wählen Sie eine Praxis aus"
            return
        }
        
        guard !passwordInput.isEmpty else {
            errorMessage = "Bitte geben Sie das Passwort ein"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Validiere Passwort (verschlüsselt via PraxisPasswordManager)
        guard dataManager.validatePassword(passwordInput, for: praxisId) else {
            errorMessage = "Passwort ist falsch"
            return
        }
        
        // Login erfolgreich
        guard let praxis = getKGGPraxis(by: praxisId) else {
            errorMessage = "Praxis nicht gefunden"
            return
        }
        
        let credentials = KGGLoginCredentials(
            praxisId: praxisId,
            praxisName: praxis.name,
            password: passwordInput,
            role: praxis.role,  // ← Nur Praxis-Name als Role
            therapistName: therapistName
        )
        
        let success = sessionManager.login(credentials: credentials)
        
        if success {
            isLoggedIn = true
            currentCredentials = sessionManager.currentCredentials
            errorMessage = nil
            passwordInput = ""
            print("✅ Login erfolgreich für Praxis: \(praxis.name)")
        } else {
            errorMessage = "Session-Fehler"
        }
    }
    
    func logout() {
        sessionManager.logout()
        isLoggedIn = false
        currentCredentials = nil
        selectedPraxisId = nil
        passwordInput = ""
        resetCode = ""
        resetTempPassword = nil
        newPasswordInput = ""
        confirmPasswordInput = ""
        errorMessage = nil
    }
    
    // MARK: - Password Reset Flow
    
    func startReset() {
        resetCode = ""
        resetTempPassword = nil
        newPasswordInput = ""
        confirmPasswordInput = ""
        errorMessage = nil
        showResetFlow = true
    }
    
    func cancelReset() {
        showResetFlow = false
        resetCode = ""
        resetTempPassword = nil
        errorMessage = nil
    }
    
    /// Schritt 1: Reset-Code validieren → temporäres Passwort generieren
    func validateResetCode() {
        guard let praxisId = selectedPraxisId else {
            errorMessage = "Bitte wählen Sie eine Praxis aus"
            return
        }
        
        guard !resetCode.isEmpty else {
            errorMessage = "Bitte geben Sie den Reset-Code ein"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let tempPassword = try dataManager.resetPassword(for: praxisId, using: resetCode)
            resetTempPassword = tempPassword
            errorMessage = nil
            print("✅ Reset-Code validiert → Temp-Passwort: \(tempPassword)")
        } catch let error as PraxisPasswordManager.PasswordError {
            errorMessage = error.errorDescription ?? "Reset fehlgeschlagen"
        } catch {
            errorMessage = "Unbekannter Fehler"
        }
    }
    
    /// Schritt 2: Neues Passwort setzen
    func setNewPassword() {
        guard let praxisId = selectedPraxisId else {
            errorMessage = "Praxis nicht gefunden"
            return
        }
        
        guard !newPasswordInput.isEmpty else {
            errorMessage = "Neues Passwort darf nicht leer sein"
            return
        }
        
        guard newPasswordInput == confirmPasswordInput else {
            errorMessage = "Passwörter stimmen nicht überein"
            return
        }
        
        guard newPasswordInput.count >= 8 else {
            errorMessage = "Passwort muss mindestens 8 Zeichen lang sein"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try dataManager.changePassword(newPassword: newPasswordInput, for: praxisId)
            errorMessage = nil
            passwordInput = newPasswordInput
            showResetFlow = false
            resetTempPassword = nil
            newPasswordInput = ""
            confirmPasswordInput = ""
            print("✅ Passwort erfolgreich geändert")
        } catch let error as PraxisPasswordManager.PasswordError {
            errorMessage = error.errorDescription ?? "Fehler beim Setzen des Passworts"
        } catch {
            errorMessage = "Unbekannter Fehler"
        }
    }
}

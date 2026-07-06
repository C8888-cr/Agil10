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
import SwiftData
import Combine

@MainActor
final class KGGAuthViewModel: ObservableObject {
    
    // MARK: - Login State
    @Published var selectedPraxisId: UUID? {
        didSet {
            if let id = selectedPraxisId {
                UserDefaults.standard.set(id.uuidString, forKey: "kgg.lastSelectedPraxisId")
            }
        }
    }
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
    
    init() {
        if let stored = UserDefaults.standard.string(forKey: "kgg.lastSelectedPraxisId"),
           let id = UUID(uuidString: stored) {
            selectedPraxisId = id
        } else {
            selectedPraxisId = getAllKGGPraxen().first?.id
        }
    }
    
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
    
    // MARK: - Passwort ändern (Settings, eingeloggt)
       
       /// Ändert das Admin-Passwort. Prüft zuerst das aktuelle Passwort.
       /// Rückgabe: true bei Erfolg (Sheet kann schließen).
       @discardableResult
       func changePassword(current: String, new: String, confirm: String) -> Bool {
           guard let praxisId = currentCredentials?.praxisId else {
               errorMessage = "Keine aktive Session"
               return false
           }
           
           guard dataManager.validatePassword(current, for: praxisId) else {
               errorMessage = "Aktuelles Passwort ist falsch"
               return false
           }
           
           guard new.count >= 8 else {
               errorMessage = "Neues Passwort muss mindestens 8 Zeichen lang sein"
               return false
           }
           
           guard new == confirm else {
               errorMessage = "Passwörter stimmen nicht überein"
               return false
           }
           
           do {
               try dataManager.changePassword(newPassword: new, for: praxisId)
               errorMessage = nil
               print("✅ Passwort geändert")
               return true
           } catch {
               errorMessage = "Fehler beim Speichern des Passworts"
               return false
           }
       }
       
       // MARK: - Praxisdaten löschen (Danger Zone)
       
       /// Löscht ALLE Daten der eingeloggten Praxis unwiderruflich:
       /// Patienten (inkl. Übungen/Warmups via Relation), Historie,
       /// Library-Übungen inkl. verschlüsselter Videos + Keychain-Keys, Kategorien.
       /// Danach: Logout. Rückgabe: true bei Erfolg.
       @discardableResult
       func deletePraxisData(password: String, modelContext: ModelContext) -> Bool {
           guard let praxisId = currentCredentials?.praxisId else {
               errorMessage = "Keine aktive Session"
               return false
           }
           
           guard dataManager.validatePassword(password, for: praxisId) else {
               errorMessage = "Passwort ist falsch"
               return false
           }
           
           isLoading = true
           defer { isLoading = false }
           
           do {
               // 1. Library-Übungen über Repository löschen
               //    (löscht auch Video-Dateien + Keychain-Keys — keine Datenreste)
               let libraryRepo = KGGLibraryRepository(modelContext: modelContext)
               let libraryExercises = try libraryRepo.fetchExercises(praxisId: praxisId)
               for exercise in libraryExercises {
                   try libraryRepo.deleteExercise(exercise)
               }
               
               // 2. Kategorie-Werte der Praxis löschen
               var catDescriptor = FetchDescriptor<KGGCategoryValue>()
               catDescriptor.predicate = #Predicate<KGGCategoryValue> { $0.praxisId == praxisId }
               for value in try modelContext.fetch(catDescriptor) {
                   modelContext.delete(value)
               }
               
               // 3. Patienten der Praxis löschen (Historie pro Patient gleich mit)
               var patDescriptor = FetchDescriptor<KGGPatient>()
               patDescriptor.predicate = #Predicate<KGGPatient> { $0.praxisId == praxisId }
               let patients = try modelContext.fetch(patDescriptor)
               
               for patient in patients {
                   let patientId = patient.id
                   var histDescriptor = FetchDescriptor<KGGExerciseHistory>()
                   histDescriptor.predicate = #Predicate<KGGExerciseHistory> { $0.patientId == patientId }
                   for entry in try modelContext.fetch(histDescriptor) {
                       modelContext.delete(entry)
                   }
                   modelContext.delete(patient)
               }
               
               try modelContext.save()
               print("🗑️ Alle Praxisdaten gelöscht für: \(praxisId)")
               
               // 4. Session beenden
               logout()
               return true
               
           } catch {
               errorMessage = "Löschen fehlgeschlagen: \(error.localizedDescription)"
               return false
           }
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

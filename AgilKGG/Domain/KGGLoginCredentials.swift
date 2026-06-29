//
//  KGGLoginCredentials.swift
//  AgilCore
//
//  Login-State für Therapeuten-App: Praxis + Admin-Passwort
//

import Foundation
import Combine
import AgilCore

public struct KGGLoginCredentials: Codable {
    public var praxisId: UUID  // ← UUID statt String
    public var praxisName: String
    public var password: String
    public var role: String  // ← Nur Praxis-Name als Role
    public var loginTime: Date
    public var therapistName: String?
    
    public init(
        praxisId: UUID,
        praxisName: String,
        password: String,
        role: String,
        therapistName: String? = nil
    ) {
        self.praxisId = praxisId
        self.praxisName = praxisName
        self.password = password
        self.role = role
        self.loginTime = Date()
        self.therapistName = therapistName
    }
}

// MARK: - Session Manager für KGG
public final class KGGSessionManager: ObservableObject {
    @Published public var isLoggedIn: Bool = false
    @Published public var currentCredentials: KGGLoginCredentials?
    @Published public var errorMessage: String?
    
    private let keychainService = "de.agil.kgg.session"
    
    public init() {
        loadSavedSession()
    }
    
    /// Login mit Credentials (nach Passwort-Validierung durch ViewModel)
    public func login(credentials: KGGLoginCredentials) -> Bool {
        self.currentCredentials = credentials
        self.isLoggedIn = true
        self.errorMessage = nil
        
        // Speichere Session in Keychain
        saveSession(credentials)
        
        return true
    }
    
    /// Logout
    public func logout() {
        isLoggedIn = false
        currentCredentials = nil
        clearSavedSession()
    }
    
    /// Session speichern (Keychain, verschlüsselt)
    private func saveSession(_ credentials: KGGLoginCredentials) {
        if let encoded = try? JSONEncoder().encode(credentials) {
            let keychain = KeychainStore(service: keychainService)
            try? keychain.save(encoded, account: "kgg_session", protection: .deviceOnly)
        }
    }
    
    /// Session laden (Keychain)
    private func loadSavedSession() {
        let keychain = KeychainStore(service: keychainService)
        if let data = try? keychain.load(account: "kgg_session"),
           let credentials = try? JSONDecoder().decode(KGGLoginCredentials.self, from: data) {
            self.currentCredentials = credentials
            self.isLoggedIn = true
        }
    }
    
    /// Session löschen
    private func clearSavedSession() {
        let keychain = KeychainStore(service: keychainService)
        keychain.delete(account: "kgg_session")
    }
}

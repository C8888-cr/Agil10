//
//  PraxisPasswordManager.swift
//  Agil10.0
//
//  Created by Christiane Roth on 28.06.26.
//


//
//  PraxisPasswordManager.swift
//  Agil
//
//  Created by Christiane Roth on 28.06.26.
//

import Foundation
import CryptoKit
import AgilCore

public final class PraxisPasswordManager {
    
    public static let shared = PraxisPasswordManager()
    
    // MARK: - Reset Codes (pro Praxis, hardcoded)
    private let resetCodes: [UUID: String] = [
        UUID(uuidString: "11111111-1111-1111-1111-111111111111")!: "ResetPraxis1",
        UUID(uuidString: "22222222-2222-2222-2222-222222222222")!: "ResetPraxis2",
        UUID(uuidString: "33333333-3333-3333-3333-333333333333")!: "ResetPraxis3",
        UUID(uuidString: "44444444-4444-4444-4444-444444444444")!: "ResetPraxis4",
        UUID(uuidString: "55555555-5555-5555-5555-555555555555")!: "ResetPraxis5",
        UUID(uuidString: "66666666-6666-6666-6666-666666666666")!: "ResetPraxis6"
    ]
    
    private let keyManager: KeyManager
    private let cryptoService: CryptoService
    private let keychain: KeychainStore
    
    private let service = "de.agil.praxis.passwords"
    
    private init() {
        self.keyManager = KeyManager()
        self.cryptoService = CryptoService()
        self.keychain = KeychainStore(service: service)
        initializeDefaultPasswords()
    }
    
    // MARK: - Public API
    
    public func validatePassword(_ password: String, for praxisId: UUID) -> Bool {
        guard let stored = getPassword(for: praxisId) else {
            return false
        }
        return password == stored
    }
    
    public func getPassword(for praxisId: UUID) -> String? {
        let account = passwordAccount(for: praxisId)
        guard let encryptedData = try? keychain.load(account: account) else {
            return nil
        }
        
        do {
            let key = try keyManager.dataKey()
            let decrypted = try cryptoService.decrypt(encryptedData, using: key)
            return String(data: decrypted, encoding: .utf8)
        } catch {
            print("❌ Fehler beim Entschlüsseln: \(error)")
            return nil
        }
    }
    
    public func setPassword(_ newPassword: String, for praxisId: UUID) throws {
        guard !newPassword.isEmpty else {
            throw PasswordError.emptyPassword
        }
        
        let key = try keyManager.dataKey()
        let plainData = Data(newPassword.utf8)
        let encryptedData = try cryptoService.encrypt(plainData, using: key)
        
        let account = passwordAccount(for: praxisId)
        try keychain.save(encryptedData, account: account, protection: .deviceOnly)
        print("✅ Passwort gespeichert (verschlüsselt)")
    }
    
    public func resetPassword(for praxisId: UUID, using resetCode: String) throws -> String {
        guard let expectedResetCode = resetCodes[praxisId] else {
            throw PasswordError.praxisNotFound
        }
        
        guard resetCode == expectedResetCode else {
            throw PasswordError.invalidResetCode
        }
        
        let tempPassword = generateTemporaryPassword()
        try setPassword(tempPassword, for: praxisId)
        
        return tempPassword
    }
    
    // MARK: - Private
    
    private func initializeDefaultPasswords() {
        let key = "praxisPasswordsInitialized_v1"
        guard !UserDefaults.standard.bool(forKey: key) else {
            return
        }
        
        let defaultPasswords: [UUID: String] = [
            UUID(uuidString: "11111111-1111-1111-1111-111111111111")!: "Praxis2026!",
            UUID(uuidString: "22222222-2222-2222-2222-222222222222")!: "Physio2026!",
            UUID(uuidString: "33333333-3333-3333-3333-333333333333")!: "KGG2026!",
            UUID(uuidString: "44444444-4444-4444-4444-444444444444")!: "Therapy2026!",
            UUID(uuidString: "55555555-5555-5555-5555-555555555555")!: "Sport2026!",
            UUID(uuidString: "66666666-6666-6666-6666-666666666666")!: "Agil2026!"
        ]
        
        for (praxisId, password) in defaultPasswords {
            do {
                try setPassword(password, for: praxisId)
            } catch {
                print("⚠️ Init-Fehler: \(error)")
            }
        }
        
        UserDefaults.standard.set(true, forKey: key)
        print("🔒 Startpasswörter initialisiert")
    }
    
    private func passwordAccount(for praxisId: UUID) -> String {
        "praxis_password_\(praxisId.uuidString)"
    }
    
    private func generateTemporaryPassword() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$"
        return String((0..<12).map { _ in chars.randomElement()! })
    }
    
    // MARK: - Errors
    
    public enum PasswordError: LocalizedError {
        case emptyPassword
        case praxisNotFound
        case invalidResetCode
        case encryptionFailed
        
        public var errorDescription: String? {
            switch self {
            case .emptyPassword: return "Passwort darf nicht leer sein"
            case .praxisNotFound: return "Praxis nicht gefunden"
            case .invalidResetCode: return "Reset-Code ist ungültig"
            case .encryptionFailed: return "Verschlüsselung fehlgeschlagen"
            }
        }
    }
}

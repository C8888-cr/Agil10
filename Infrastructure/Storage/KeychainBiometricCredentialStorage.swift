//
//  KeychainBiometricCredentialStorage.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.05.26.
//


import Foundation
import Security
import LocalAuthentication

final class KeychainBiometricCredentialStorage: BiometricCredentialStorage {
    
    private let service = "com.agil.biometric.credentials"
    
    var hasStoredCredentials: Bool {
        let context = LAContext()
        context.interactionNotAllowed = true  // Verhindert Face-ID-Prompt nur fürs Prüfen
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "email",
            kSecUseAuthenticationContext as String: context
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }
    
    func save(email: String, password: String) throws {
        clear()
        
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            nil
        ) else {
            print("❌ AccessControl konnte nicht erstellt werden!")
            throw NSError(domain: "Keychain", code: -1)
        }
        print("✅ AccessControl erstellt mit .biometryCurrentSet")
        
        try addItem(account: "email", value: email, access: access)
        try addItem(account: "password", value: password, access: access)
        print("✅ Credentials gespeichert mit Biometrie-Schutz")
    }
    
    func load() async throws -> (email: String, password: String) {
        print("🔐 Keychain: Lade Credentials (sollte Face ID auslösen)")
        let context = LAContext()
        context.localizedReason = "Mit Face ID anmelden"
        
        let email = try loadItem(account: "email", context: context)
        print("🔐 Keychain: Email geladen: \(email)")
        let password = try loadItem(account: "password", context: context)
        print("🔐 Keychain: Erfolg")
        return (email, password)
    }
    
    func clear() {
        for account in ["email", "password"] {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
    
    // MARK: - Private
    
    private func addItem(account: String, value: String, access: SecAccessControl) throws {
        guard let data = value.data(using: .utf8) else {
            throw NSError(domain: "Keychain", code: -2)
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: access
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "Keychain", code: Int(status))
        }
    }
    
    private func loadItem(account: String, context: LAContext) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Keychain", code: Int(status))
        }
        return str
    }
}

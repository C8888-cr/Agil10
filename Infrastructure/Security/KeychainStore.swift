//
//  KeychainStore.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.06.26.
//


//
//  KeychainStore.swift
//  Agil
//
//  Einheitliche Low-Level-Keychain-Schicht (Single Source of Truth).
//  Deckt einfache Daten, gerätegebundene Schlüssel und
//  biometrie-geschützte Credentials ab.
//

import Foundation
import Security
import LocalAuthentication

struct KeychainStore {

    let service: String

    init(service: String) {
        self.service = service
    }

    /// Schutzniveau eines Eintrags.
    enum Protection {
        /// Gerätegebunden, lesbar wenn das Gerät entsperrt ist. Für Schlüssel & normale Daten.
        case deviceOnly
        /// Gerätegebunden + Biometrie/Passcode-Pflicht beim Lesen. Für Credentials.
        case biometric
    }

    enum KeychainError: LocalizedError {
        case unexpectedStatus(OSStatus)
        case accessControlCreationFailed

        var errorDescription: String? {
            switch self {
            case .unexpectedStatus(let status): return "Keychain-Fehler (\(status))."
            case .accessControlCreationFailed:  return "Zugriffsschutz konnte nicht erstellt werden."
            }
        }
    }

    // MARK: - Save

    func save(_ data: Data, account: String, protection: Protection = .deviceOnly) throws {
        delete(account: account)

        var attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        switch protection {
        case .deviceOnly:
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .biometric:
            guard let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .biometryCurrentSet,
                nil
            ) else { throw KeychainError.accessControlCreationFailed }
            attributes[kSecAttrAccessControl as String] = access
        }

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }

    func save(_ string: String, account: String, protection: Protection = .deviceOnly) throws {
        try save(Data(string.utf8), account: account, protection: protection)
    }

    // MARK: - Load

    /// Lädt Daten. Bei biometrie-geschützten Einträgen einen `LAContext` übergeben (löst Face ID aus).
    func load(account: String, context: LAContext? = nil) throws -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let context { query[kSecUseAuthenticationContext as String] = context }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:      return result as? Data
        case errSecItemNotFound: return nil
        default:                 throw KeychainError.unexpectedStatus(status)
        }
    }

    func loadString(account: String, context: LAContext? = nil) throws -> String? {
        guard let data = try load(account: account, context: context) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Exists (ohne Biometrie-Prompt)

    func exists(account: String) -> Bool {
        let context = LAContext()
        context.interactionNotAllowed = true
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseAuthenticationContext as String: context
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    // MARK: - Delete

    func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
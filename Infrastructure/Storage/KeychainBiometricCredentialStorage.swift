//
//  KeychainBiometricCredentialStorage.swift
//  Agil
//
//  Speichert Login-Credentials biometrie-geschützt für den Face-ID-Login.
//  Nutzt jetzt den zentralen KeychainStore.
//

import Foundation
import Security
import LocalAuthentication
import AgilCore


final class KeychainBiometricCredentialStorage: BiometricCredentialStorage {

    private let keychain = KeychainStore(service: "com.agil.biometric.credentials")
    private let emailAccount = "email"
    private let passwordAccount = "password"

    var hasStoredCredentials: Bool {
        keychain.exists(account: emailAccount)
    }

    func save(email: String, password: String) throws {
        clear()
        try keychain.save(email, account: emailAccount, protection: .biometric)
        try keychain.save(password, account: passwordAccount, protection: .biometric)
    }

    func load() async throws -> (email: String, password: String) {
        let context = LAContext()
        context.localizedReason = "Mit Face ID anmelden"

        guard let email = try keychain.loadString(account: emailAccount, context: context),
              let password = try keychain.loadString(account: passwordAccount, context: context) else {
            throw KeychainStore.KeychainError.unexpectedStatus(errSecItemNotFound)
        }
        return (email, password)
    }

    func clear() {
        keychain.delete(account: emailAccount)
        keychain.delete(account: passwordAccount)
    }
}

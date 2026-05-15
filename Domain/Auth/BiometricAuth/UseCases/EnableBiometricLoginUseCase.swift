//
//  EnableBiometricLoginUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//
import Foundation

// Domain/UseCases/EnableBiometricLoginUseCase.swift
struct EnableBiometricLoginUseCase {
    private let authenticator: BiometricAuthenticator
    private let preferences: BiometricPreferences
    
    init(authenticator: BiometricAuthenticator, preferences: BiometricPreferences) {
        self.authenticator = authenticator
        self.preferences = preferences
    }
    
    func execute() async throws {
        let biometry = authenticator.availableBiometry()
        guard biometry != .none else {
            throw BiometricAuthError.notAvailable
        }
        try await authenticator.authenticate(
            reason: "Aktiviere die biometrische Anmeldung."
        )
        preferences.setBiometricLoginEnabled(true)
    }
}

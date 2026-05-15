//
//  UnlockAppUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//
import Foundation

// Domain/UseCases/UnlockAppUseCase.swift
struct UnlockAppUseCase {
    private let authenticator: BiometricAuthenticator
    private let preferences: BiometricPreferences
    
    init(authenticator: BiometricAuthenticator, preferences: BiometricPreferences) {
        self.authenticator = authenticator
        self.preferences = preferences
    }
    
    func execute() async throws {
        guard preferences.isBiometricLoginEnabled else { return }
        try await authenticator.authenticate(
            reason: "Bitte authentifiziere dich um die App zu nutzen."
        )
    }
}

//
//  DisableBiometricLoginUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//
import Foundation

struct DisableBiometricLoginUseCase {
    private let preferences: BiometricPreferences
    
    init(preferences: BiometricPreferences) {
        self.preferences = preferences
    }
    
    func execute() {
        preferences.setBiometricLoginEnabled(false)
    }
}

//
//  UserDefaultsBiometricPreferences.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//
import Foundation

final class UserDefaultsBiometricPreferences: BiometricPreferences {
    private let defaults = UserDefaults.standard
    private let key = "biometric_login_enabled"
    
    var isBiometricLoginEnabled: Bool {
        true  // App-Sperre ist immer aktiv
    }
    
    func setBiometricLoginEnabled(_ enabled: Bool) {
        // Bewusst leer — die Sperre lässt sich nicht deaktivieren
           
    }
}

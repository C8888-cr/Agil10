//
//  BiometricPreferences.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//
import Foundation

// Domain/Preferences/BiometricPreferences.swift
protocol BiometricPreferences {
    var isBiometricLoginEnabled: Bool { get }
    func setBiometricLoginEnabled(_ enabled: Bool)
}

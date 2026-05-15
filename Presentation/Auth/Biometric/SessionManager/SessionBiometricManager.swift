//
//  SessionManager.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//
import Foundation

@MainActor
final class SessionBiometricManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var requiresBiometricUnlock = false
    @Published var currentUser: User?
    
    private let unlockUseCase: UnlockAppUseCase
    private let preferences: BiometricPreferences
    
    init(unlockUseCase: UnlockAppUseCase, preferences: BiometricPreferences) {
        self.unlockUseCase = unlockUseCase
        self.preferences = preferences
    }
    
    func lockSession() {
        guard isAuthenticated else { return }
        guard preferences.isBiometricLoginEnabled else { return }
        requiresBiometricUnlock = true
    }
    
    func unlockSession() async throws {
        try await unlockUseCase.execute()
        requiresBiometricUnlock = false
    }
}

//
//  LoginWithBiometricUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.05.26.
//
import Foundation

struct LoginWithBiometricUseCase {
    private let credentialStorage: BiometricCredentialStorage
    private let authService: AuthServiceProtocol
    
    init(credentialStorage: BiometricCredentialStorage, authService: AuthServiceProtocol) {
        self.credentialStorage = credentialStorage
        self.authService = authService
    }
    
    func execute() async throws -> AuthUser {
        let (email, password) = try await credentialStorage.load()
        return try await authService.login(email: email, password: password)
    }
}

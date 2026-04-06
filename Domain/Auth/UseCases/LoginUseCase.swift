//
//  LoginUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


final class LoginUseCase {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func execute(email: String, password: String) async throws -> AuthUser {
        // Hier könnte Validierungslogik rein – unabhängig von Firebase
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        return try await authService.login(email: email, password: password)
    }
}
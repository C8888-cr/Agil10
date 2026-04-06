//
//  ResetPasswordUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


final class ResetPasswordUseCase {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func execute(email: String) async throws {
        guard !email.isEmpty else {
            throw AuthError.invalidCredentials
        }
        try await authService.resetPassword(email: email)
    }
}
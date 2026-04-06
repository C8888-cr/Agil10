//
//  SignOutUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


final class SignOutUseCase {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func execute() throws {
        try authService.signOut()
    }
}
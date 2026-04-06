final class SignUpUseCase {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func execute(request: SignUpRequest) async throws -> AuthUser {
        guard !request.email.isEmpty, !request.password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        guard request.password.count >= 6 else {
            throw AuthError.passwordTooShort
        }
        guard !request.firstName.isEmpty, !request.lastName.isEmpty else {
            throw AuthError.invalidCredentials
        }
        guard request.praxisId != nil else {
            throw AuthError.invalidCredentials
        }
        return try await authService.signUp(
            email: request.email,
            password: request.password,
            firstName: request.firstName,
            lastName: request.lastName,
            praxisId: request.praxisId
        )
    }
}

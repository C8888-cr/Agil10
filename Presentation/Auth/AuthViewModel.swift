import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading = false

    let session: SessionManager

    private let loginUseCase: LoginUseCase
    private let signUpUseCase: SignUpUseCase
    private let signOutUseCase: SignOutUseCase
    private let resetPasswordUseCase: ResetPasswordUseCase

    init(
        session: SessionManager,
        loginUseCase: LoginUseCase,
        signUpUseCase: SignUpUseCase,
        signOutUseCase: SignOutUseCase,
        resetPasswordUseCase: ResetPasswordUseCase
    ) {
        self.session = session
        self.loginUseCase = loginUseCase
        self.signUpUseCase = signUpUseCase
        self.signOutUseCase = signOutUseCase
        self.resetPasswordUseCase = resetPasswordUseCase
    }

    func login(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let authUser = try await loginUseCase.execute(email: email, password: password)
            session.setAuthenticatedUser(authUser)  // ← explizit, kein Firebase-Seiteneffekt
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(request: SignUpRequest) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let authUser = try await signUpUseCase.execute(request: request)
            session.setAuthenticatedUser(authUser)  // ← Namen kommen aus dem Request
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await signOutUseCase.execute()
            session.clearSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword(email: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await resetPasswordUseCase.execute(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

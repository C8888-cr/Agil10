import Foundation

protocol AuthServiceProtocol {
    var currentUser: AuthUser? { get }
    func login(email: String, password: String) async throws -> AuthUser
    func signUp(email: String, password: String, firstName: String,
                lastName: String, praxisId: UUID?) async throws -> AuthUser
    func signOut() throws
    func resetPassword(email: String) async throws
    func deleteAccount() async throws
}

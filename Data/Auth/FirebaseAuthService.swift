import FirebaseAuth
import Foundation

final class FirebaseAuthService: AuthServiceProtocol {
    
    var currentUser: AuthUser? {
        guard let user = Auth.auth().currentUser else { return nil }
        return AuthUser(
            uid: user.uid,
            email: user.email ?? "",
            firstName: "",
            lastName: "",
            praxisId: nil
        )
    }

    func login(email: String, password: String) async throws -> AuthUser {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthUser(
            uid: result.user.uid,
            email: result.user.email ?? "",
            firstName: "",
            lastName: "",
            praxisId: nil
        )
    }
    
    func signUp(email: String, password: String, firstName: String,
                lastName: String, praxisId: UUID?) async throws -> AuthUser {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        // Kein displayName! Namen bleiben nur in SwiftData.
        return AuthUser(
            uid: result.user.uid,
            email: result.user.email ?? "",
            firstName: firstName,
            lastName: lastName,
            praxisId: praxisId
        )
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    func deleteAccount() async throws {
            try await Auth.auth().currentUser?.delete()
        }
    
}

import FirebaseAuth
import Foundation
/*
class FirebaseAuthService: AuthServiceProtocol {
    
    func login(email: String, password: String) async throws -> (user: User, sessionToken: String) {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let token = try await result.user.getIDToken()
            let user = mapFirebaseUser(result.user)
            return (user, token)
        } catch {
            throw AuthError.invalidCredentials
        }
    }
    
    func signUp(email: String, password: String, firstName: String,
                lastName: String, role: UserRole, praxisId: UUID?) async throws -> (user: User, sessionToken: String) {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let token = try await result.user.getIDToken()
            
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = "\(firstName) \(lastName)"
            try await changeRequest.commitChanges()
            
            let user = User(
                email: email,
                passwordHash: "firebase",
                role: role,
                praxisId: praxisId
            )
            user.firstName = firstName
            user.lastName = lastName
            user.firebaseUID = result.user.uid  // ← NEU
            return (user, token)
        } catch {
            throw AuthError.invalidCredentials
        }
    }
    
    func fetchCurrentUser() async throws -> User? {
        guard let firebaseUser = Auth.auth().currentUser else { return nil }
        return mapFirebaseUser(firebaseUser)
    }
    
    func logout() async {
        try? Auth.auth().signOut()
    }
    
    func sendPasswordResetEmail(email: String) async throws -> String {
        try await Auth.auth().sendPasswordReset(withEmail: email)
        return ""
    }
    
    func confirmPasswordReset(email: String, resetCode: String, newPassword: String) async throws {
        try await Auth.auth().confirmPasswordReset(withCode: resetCode, newPassword: newPassword)
    }
    
    // MARK: - Helper
    // ✅ firebaseUID wird jetzt gesetzt — das war der einzige fehlende Fix!
    private func mapFirebaseUser(_ firebaseUser: FirebaseAuth.User) -> User {
        let nameParts = (firebaseUser.displayName ?? "").split(separator: " ")
        let user = User(
            email: firebaseUser.email ?? "",
            passwordHash: "firebase",
            role: .patient,
            praxisId: nil
        )
        user.firstName = nameParts.first.map(String.init) ?? ""
        user.lastName = nameParts.dropFirst().first.map(String.init) ?? ""
        user.firebaseUID = firebaseUser.uid  // ← das ist der eigentliche Fix!
        return user
    }
}
*/
import Firebase

final class FirebaseAuthService: AuthServiceProtocol {
    
    var currentUser: AuthUser? {
        guard let user = Auth.auth().currentUser else { return nil }
        let nameParts = (user.displayName ?? "").split(separator: " ")
        return AuthUser(
            uid: user.uid,
            email: user.email ?? "",
            firstName: nameParts.first.map(String.init) ?? "",
            lastName: nameParts.dropFirst().first.map(String.init) ?? "",
            praxisId: nil
        )
    }

    func login(email: String, password: String) async throws -> AuthUser {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let nameParts = (result.user.displayName ?? "").split(separator: " ")
        return AuthUser(
            uid: result.user.uid,
            email: result.user.email ?? "",
            firstName: nameParts.first.map(String.init) ?? "",
            lastName: nameParts.dropFirst().first.map(String.init) ?? "",
            praxisId: nil
        )
    }
    
    
    func signUp(email: String, password: String, firstName: String,
                lastName: String, praxisId: UUID?) async throws -> AuthUser {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = "\(firstName) \(lastName)"
        try await changeRequest.commitChanges()
        
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
}

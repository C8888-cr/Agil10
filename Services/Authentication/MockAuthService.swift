import SwiftUI
import SwiftData


final class MockAuthService: AuthServiceProtocol, ObservableObject {
    private weak var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    private var activeTokens: [String: String] = [:]
    
    static let mockPatientId = UUID(uuidString: "12345678-1234-5678-1234-123456789ABC")!
    static let mockTherapistId = UUID(uuidString: "87654321-4321-8765-4321-CBA987654321")!
    
    struct MockUserRecord {
        let id: UUID
        let email: String
        let firstName: String
        let lastName: String
        let password: String
        let isTherapist: Bool
        let praxisId: UUID?
        
        func toUser() -> User {
            User(
                id: id,
                firstName: firstName,
                lastName: lastName,
                email: email,
                passwordHash: password,
                role: isTherapist ? .therapist : .patient,
                praxisId: praxisId
            )
        }
    }

    private var mockUsers: [String: MockUserRecord] = [
        "patient@agil.de": MockUserRecord(
            id: MockAuthService.mockPatientId,
            email: "patient@agil.de",
            firstName: "Max",
            lastName: "Mustermann",
            password: "patient1",
            isTherapist: false,
            praxisId: PraxisDataManager.praxis4Id
        ),
        "therapist@agil.de": MockUserRecord(
            id: MockAuthService.mockTherapistId,
            email: "therapist@agil.de",
            firstName: "Christiane",
            lastName: "Roth",
            password: "therapist1",
            isTherapist: true,
            praxisId: PraxisDataManager.praxis4Id
        )
    ]
    
    // ✅ SIGN UP
    func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        praxisId: UUID?
    ) async throws -> (user: User, sessionToken: String) {
        
        print("🔧 MockAuthService.signUp() START")
          print("   email: \(email)")
          print("   firstName: \(firstName)")
          print("   lastName: \(lastName)")
          print("   role: \(role)")
        
        if mockUsers[email.lowercased()] != nil {
            throw AuthError.emailAlreadyExists
        }
        
        let newUserId = UUID()
        let newRecord = MockUserRecord(
            id: newUserId,
            email: email.lowercased(),
            firstName: firstName,
            lastName: lastName,
            password: password,
            isTherapist: role == .therapist,
            praxisId: praxisId
        )
        
        
        
        mockUsers[email.lowercased()] = newRecord
        
        let newUser = User(
            id: newUserId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            passwordHash: "",
            role: role,
            praxisId: praxisId
        )
        print("✅ User-Objekt erstellt: \(newUser.fullName)")
        
        // ✅ In SwiftData speichern
          if let context = modelContext {
              context.insert(newUser)
              
              do {
                  try context.save()
                  print("✅ User in SwiftData gespeichert!")
                  
                  // ✅ Verify
                  let descriptor = FetchDescriptor<User>(
                      predicate: #Predicate<User> { u in
                          u.id == newUserId
                      }
                  )
                  if let savedUser = try? context.fetch(descriptor).first {
                      print("✅ VERIFY: User aus DB geladen: \(savedUser.fullName)")
                  }
                  
              } catch {
                  print("❌ FEHLER beim Speichern: \(error)")
                  print("   Context: \(context)")
              }
          } else {
              print("⚠️ KEIN ModelContext vorhanden!")
          }
          
          let token = "mock-token-\(UUID().uuidString)"
          activeTokens[token] = email.lowercased()
          
          print("✅ MockAuthService: User registriert")
          print("🔑 Token: \(token)")
          
          try await Task.sleep(nanoseconds: 1_500_000_000)
          
        return (user: newUser, sessionToken: token)
      }
    
    // ✅ LOGIN - FIXED
    func login(email: String, password: String) async throws -> (user: User, sessionToken: String) {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        guard let record = mockUsers[email.lowercased()] else {
            throw AuthError.userNotFound
        }
        
        guard record.password == password else {
            throw AuthError.invalidCredentials
        }
        
        var user: User
        
        if let context = modelContext {
            // ✅ Email vorher extrahieren
            let emailLowercase = email.lowercased()
            
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate<User> { u in
                    u.email == emailLowercase
                }
            )
            
            if let existingUser = try? context.fetch(descriptor).first {
                user = existingUser
                print("✅ User aus SwiftData geladen: \(user.fullName)")
                
            } else {
                user = record.toUser()
                context.insert(user)
                try? context.save()
                print("✅ User in SwiftData gespeichert")
            }
        } else {
            user = record.toUser()
        }
        
        let token = "mock-token-\(UUID().uuidString)"
        activeTokens[token] = email.lowercased()
        
        print("✅ Mock Login erfolgreich für: \(email)")
        print("🔑 Token: \(token)")
        
        return (user, sessionToken: token)
    }
    
    // ✅ FETCH CURRENT USER - FIXED
    func fetchCurrentUser() async throws -> User? {
        guard let token = KeychainHelper.load(forKey: "sessionToken") else {
            return nil
        }
        
        guard let email = activeTokens[token] else {
            return nil
        }
        
        guard let context = modelContext else {
            print("❌ Kein ModelContext vorhanden")
            return nil
        }
        
        // ✅ Email vorher extrahieren
        let emailLowercase = email.lowercased()
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.email == emailLowercase
            }
        )
        
        guard let user = try? context.fetch(descriptor).first else {
            print("❌ User nicht in SwiftData gefunden: \(email)")
            return nil
        }
        
        print("✅ Mock: Current User aus SwiftData geladen")
        print("   Name: \(user.fullName)")
        return user
    }
    
    // ✅ LOGOUT
    func logout() async {
        print("👋 Mock Logout")
    }
    
    // ✅ PASSWORD RESET EMAIL
    func sendPasswordResetEmail(email: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard mockUsers[email.lowercased()] != nil else {
            throw AuthError.userNotFound
        }
        
        let resetCode = String(UUID().uuidString.prefix(6))
        print("📧 Password Reset Code für \(email): \(resetCode)")
        return resetCode
    }
    
    // ✅ CONFIRM PASSWORD RESET
    func confirmPasswordReset(email: String, resetCode: String, newPassword: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard ValidationHelper.isValidPassword(newPassword) else {
            throw AuthError.passwordTooShort
        }
        
        guard let record = mockUsers[email.lowercased()] else {
            throw AuthError.userNotFound
        }
        
        let updatedRecord = MockUserRecord(
            id: record.id,
            email: record.email,
            firstName: record.firstName,
            lastName: record.lastName,
            password: newPassword,
            isTherapist: record.isTherapist,
            praxisId: record.praxisId
        )
        mockUsers[email.lowercased()] = updatedRecord
        
        print("✅ Passwort zurückgesetzt für: \(email)")
    }
}

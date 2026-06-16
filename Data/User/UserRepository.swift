import SwiftData
import Foundation

final class UserRepository {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    
    func fetchUser(by id: UUID) -> User? {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }

    func findOrCreate(firebaseUID: String, email: String,
                          firstName: String = "",
                          lastName: String = "",
                          praxisId: UUID? = nil) -> User {
            // 1. Nach firebaseUID suchen
            if !firebaseUID.isEmpty {
                let descriptor = FetchDescriptor<User>(
                    predicate: #Predicate { $0.firebaseUID == firebaseUID }
                )
                if let existing = (try? modelContext.fetch(descriptor))?.first {
                    apply(firstName: firstName, lastName: lastName, praxisId: praxisId, to: existing)
                    return existing
                }
            }

            // 2. Fallback: nach Email suchen
            let emailDescriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.email == email }
            )
            if let existing = (try? modelContext.fetch(emailDescriptor))?.first {
                if existing.firebaseUID.isEmpty && !firebaseUID.isEmpty {
                    existing.firebaseUID = firebaseUID
                }
                apply(firstName: firstName, lastName: lastName, praxisId: praxisId, to: existing)
                return existing
            }

            // 3. Neuen User anlegen
            let newUser = User(email: email, passwordHash: "local", role: .patient, praxisId: praxisId)
            newUser.firebaseUID = firebaseUID
            newUser.firstName = firstName
            newUser.lastName = lastName
            modelContext.insert(newUser)
            try? modelContext.save()
            print("🆕 Neuer User angelegt: \(email)")
            return newUser
        }
    
    /// Aktualisiert nur nicht-leere Felder, überschreibt vorhandene Daten also nicht mit Leerwerten.
        private func apply(firstName: String, lastName: String, praxisId: UUID?, to user: User) {
            var changed = false
            if !firstName.isEmpty, user.firstName != firstName { user.firstName = firstName; changed = true }
            if !lastName.isEmpty,  user.lastName  != lastName  { user.lastName  = lastName;  changed = true }
            if let praxisId, user.praxisId != praxisId         { user.praxisId  = praxisId;  changed = true }
            if changed { try? modelContext.save() }
        }

    func update(user: User, firstName: String, lastName: String) throws {
        user.firstName = firstName
        user.lastName = lastName
        try modelContext.save()
    }
    
    // UserRepository.swift — delete Methode ergänzen
    func delete(userId: UUID) throws {
        guard let user = fetchUser(by: userId) else { return }
        modelContext.delete(user)
        try modelContext.save()
    }
}

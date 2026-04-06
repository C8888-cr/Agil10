//
//  UserRepository.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import SwiftData
import Foundation

final class UserRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func findOrCreate(firebaseUID: String, email: String) -> User {
        // 1. Nach firebaseUID suchen
        if !firebaseUID.isEmpty {
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.firebaseUID == firebaseUID }
            )
            if let existing = (try? modelContext.fetch(descriptor))?.first {
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
                try? modelContext.save()
            }
            return existing
        }

        // 3. Neuen User anlegen
        let newUser = User(email: email, passwordHash: "firebase", role: .patient, praxisId: nil)
        newUser.firebaseUID = firebaseUID
        modelContext.insert(newUser)
        try? modelContext.save()
        return newUser
    }

    func update(user: User, firstName: String, lastName: String) throws {
        user.firstName = firstName
        user.lastName = lastName
        try modelContext.save()
    }
}
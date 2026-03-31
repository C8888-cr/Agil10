//
//  User.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//

import SwiftData
import Foundation



@Model
final class User: @unchecked Sendable { 
    @Attribute(.unique) var id: UUID  // ← HINZUFÜGEN!
    @Attribute(.externalStorage) var profileImage: Data?
    
    
    var firebaseUID: String = ""
    
    //Persönliche Daten
        var firstName: String
        var lastName: String
        var dateOfBirth: Date?
    
    // Account
    var email: String
    var passwordHash: String
    var roleRaw: String
    var isPremium: Bool
    var createdAt: Date
    
    var praxisId: UUID?
    var preferences: UserPreferences?
    
    var role: UserRole {
        get { UserRole(rawValue: roleRaw) ?? .patient }
        set { roleRaw = newValue.rawValue }
            }
    
    // ✅ NEU: Voller Name
       var fullName: String {
           "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
       }
       
       // ✅ NEU: Initialen für Avatar
       var initials: String {
           let firstInitial = firstName.first.map(String.init) ?? ""
           let lastInitial = lastName.first.map(String.init) ?? ""
           return "\(firstInitial)\(lastInitial)".uppercased()
       }
       
       // ✅ NEU: Alter berechnen
       var age: Int? {
           guard let dateOfBirth else { return nil }
           let calendar = Calendar.current
           let now = Date()
           let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
           return ageComponents.year
       }
            
            init(
                id: UUID = UUID(),
                firstName: String = "",
                lastName: String = "",
                dateOfBirth: Date? = nil,
                email: String = "",
                passwordHash: String,
                role: UserRole,
                isPremium: Bool = false,
                praxisId: UUID? = nil
            ) {
                self.id = id
                self.firstName = firstName
                self.lastName = lastName
                self.dateOfBirth = dateOfBirth
                self.email = email
                self.passwordHash = passwordHash
                self.roleRaw = role.rawValue
                self.isPremium = isPremium
                self.createdAt = Date()
                self.praxisId = praxisId ?? PraxisDataManager.praxis2Id
            }
        }


extension User {
    @MainActor static func mockPatient() -> User {
        let user = User(
            id: MockAuthService.mockPatientId,
            firstName: "Max",
            lastName: "Mustermann",
            email: "patient@agil.de",
            passwordHash: "patient1",
            role: .patient,
            praxisId: PraxisDataManager.praxis4Id
        )
        print("🧪 mockPatient erstellt – praxisId: \(String(describing: user.praxisId))")
        return user
    }

    
    @MainActor static func mockTherapist() -> User {
        User(
            id: UUID(),
            firstName: "Dr. Sarah",
            lastName: "Müller",
            email: "therapeut@agil.de",
            passwordHash: "therapeut1",
            role: .therapist,
            praxisId: PraxisDataManager.praxis4Id 
        )
    }
}

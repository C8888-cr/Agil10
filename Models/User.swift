//
//  User.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//

import SwiftData
import Foundation


@Model
final class User {
    @Attribute(.unique) var id: UUID
    
    // ✅ NEU: Persönliche Daten
        var firstName: String
        var lastName: String
        var dateOfBirth: Date?
    
    // Account
    var email: String
    var passwordHash: String
    var roleRaw: String
    var isPremium: Bool
    var createdAt: Date
    
    // Relationships
    var practice: Praxis?
    var preferences: UserPreferences?
    
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]?
    @Relationship(deleteRule: .cascade) var appointments: [Appointment]?
    @Relationship(deleteRule: .cascade) var videoLibrary: [Video]?
    @Relationship(deleteRule: .cascade) var videoSchedules: [VideoSchedule]?  // ✅ Auch das hinzufügen!
    
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
                role: UserRole = .patient,
                isPremium: Bool = false,
                practice: Praxis? = nil
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
                self.practice = practice
            }
        }

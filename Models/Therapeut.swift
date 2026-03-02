//
//  Therapeut.swift
//  Agil10.0
//
//  Created by Christiane Roth on 23.02.26.
//


// Therapeut.swift
import Foundation
final class Therapeut: @unchecked Sendable, Identifiable {
    var id: UUID
    var firstName: String
    var lastName: String
    var praxisId: UUID
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        praxisId: UUID
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.praxisId = praxisId

    }
}

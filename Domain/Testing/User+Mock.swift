//
//  User+Mock.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//
import Foundation

extension User {
    @MainActor static func mockPatient() -> User {
        let user = User(
            id: MockData.patientId,
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

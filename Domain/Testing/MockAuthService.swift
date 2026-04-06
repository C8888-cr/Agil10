//
//  MockAuthService.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation

final class MockAuthService: AuthServiceProtocol {
    
    var currentUser: AuthUser? = nil
    
    func login(email: String, password: String) async throws -> AuthUser {
        let user = AuthUser(
            uid: MockData.patientId.uuidString,
            email: email,
            firstName: "Max",
            lastName: "Mustermann",
            praxisId: MockData.praxisId
        )
        currentUser = user
        return user
    }
    
    func signUp(email: String, password: String, firstName: String,
                lastName: String, praxisId: UUID?) async throws -> AuthUser {
        let user = AuthUser(
            uid: MockData.patientId.uuidString,
            email: email,
            firstName: firstName,
            lastName: lastName,
            praxisId: praxisId
        )
        currentUser = user
        return user
    }
    
    func signOut() throws {
        currentUser = nil
    }
    
    func resetPassword(email: String) async throws {}
}
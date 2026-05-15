// Domain/Auth/AuthUser.swift
import Foundation

struct AuthUser {
    let uid: String
    let email: String
    let role: UserRole = .patient  // ← immer patient
    let firstName: String
    let lastName: String
    let praxisId: UUID?
}

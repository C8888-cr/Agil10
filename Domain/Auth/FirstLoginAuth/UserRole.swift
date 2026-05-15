//
//  UserRole.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//

import Foundation
enum UserRole: String, Codable, Sendable {
    case patient
    case therapist
    case admin
}

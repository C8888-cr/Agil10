//
//  UserRole.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import SwiftData
import Foundation
enum UserRole: String, Codable {
    case patient
    case therapist
    case admin
}
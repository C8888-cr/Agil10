//
//  BiometricAuthError.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//
import Foundation

enum BiometricAuthError: Error, Equatable {
    case notAvailable
    case notEnrolled
    case userCancelled
    case authenticationFailed
    case lockout
    case unknown
}

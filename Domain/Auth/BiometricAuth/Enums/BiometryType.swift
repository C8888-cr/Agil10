//
//  BiometryType.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//


// Domain/Authentication/BiometricAuthenticator.swift
import Foundation

enum BiometryType {
    case none
    case faceID
    case touchID
    case other  // Android Fingerprint, Iris, etc.
}





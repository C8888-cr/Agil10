//
//  BiometricAuthenticator.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//
import Foundation

protocol BiometricAuthenticator {
    func availableBiometry() -> BiometryType
    func authenticate(reason: String) async throws
}

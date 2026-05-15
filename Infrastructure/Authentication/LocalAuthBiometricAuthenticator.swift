//
//  LocalAuthBiometricAuthenticator.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//
import Foundation

// Infrastructure/Authentication/LocalAuthBiometricAuthenticator.swift
import LocalAuthentication

final class LocalAuthBiometricAuthenticator: BiometricAuthenticator {
    
    func availableBiometry() -> BiometryType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID:  return .faceID
        case .touchID: return .touchID
        case .opticID: return .other
        case .none:    return .none
        @unknown default: return .other
        }
    }
    
    func authenticate(reason: String) async throws {
        let context = LAContext()
        context.localizedFallbackTitle = "Passwort verwenden"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw mapNSError(error)
        }
        
        do {
            try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch let laError as LAError {
            throw mapLAError(laError)
        } catch {
            throw BiometricAuthError.unknown
        }
    }
    
    private func mapNSError(_ error: NSError?) -> BiometricAuthError {
        guard let error else { return .unknown }
        switch error.code {
        case LAError.biometryNotAvailable.rawValue: return .notAvailable
        case LAError.biometryNotEnrolled.rawValue:  return .notEnrolled
        case LAError.biometryLockout.rawValue:      return .lockout
        default: return .authenticationFailed
        }
    }
    
    private func mapLAError(_ error: LAError) -> BiometricAuthError {
        switch error.code {
        case .userCancel, .appCancel, .systemCancel: return .userCancelled
        case .biometryLockout:    return .lockout
        case .biometryNotAvailable: return .notAvailable
        case .biometryNotEnrolled:  return .notEnrolled
        default: return .authenticationFailed
        }
    }
}

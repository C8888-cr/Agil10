//
//  KGGPraxis.swift
//  Agil
//
//  Created by Christiane Roth on 28.06.26.
//
//  Wrapper um Praxis für Therapeuten-App
//  - Praxis-Daten (Adresse, Kontakt, etc.)
//  - Passwort-Management integriert (verschlüsselt)
//  - Role: Nur Praxis-Name
//

import Foundation

/// KGG-Therapeuten-Praxis: Wrapper um Praxis mit Auth-Logik
public struct KGGPraxis: Identifiable {
    public let id: UUID
    public let praxis: Praxis  // ← Echte Praxis-Daten
    
    public var name: String { praxis.name }
    public var email: String? { praxis.email }
    public var address: String? { praxis.fullAddress }
    public var city: String? { praxis.city }
    public var phone: String? { praxis.telefon }
    public var website: String? { praxis.website }
    
    /// Role ist der Praxis-Name (als String für Auth)
    public var role: String { praxis.name }
    
    public init(from praxis: Praxis) {
        self.id = praxis.id
        self.praxis = praxis
    }
}

// MARK: - Auth Helper

extension KGGPraxis {
    /// Validiert Passwort gegen diesen Praxis
    public func validatePassword(_ password: String) -> Bool {
        PraxisDataManager.shared.validatePassword(password, for: id)
    }
    
    /// Startet Password-Reset mit Reset-Code (z.B. "ResetPraxis1")
    public func resetPassword(using resetCode: String) throws -> String {
        try PraxisDataManager.shared.resetPassword(for: id, using: resetCode)
    }
    
    /// Ändert das Passwort (therapeut muss eingeloggt sein)
    public func changePassword(to newPassword: String) throws {
        try PraxisDataManager.shared.changePassword(newPassword: newPassword, for: id)
    }
}

// MARK: - Factory

/// Konvertiert alle Praxen zu KGGPraxis-Wrapper
public func getAllKGGPraxen() -> [KGGPraxis] {
    PraxisDataManager.shared.praxen.map { KGGPraxis(from: $0) }
}

/// Findet KGGPraxis by UUID
public func getKGGPraxis(by id: UUID) -> KGGPraxis? {
    guard let praxis = PraxisDataManager.shared.getPraxis(by: id) else {
        return nil
    }
    return KGGPraxis(from: praxis)
}

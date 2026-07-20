//
//  KGGWarmup.swift
//  Agil10.0
//
//  Created by Christiane Roth on 27.06.26.
//


//
//  KGGWarmup.swift
//  AgilCore
//
//  Warmup-Konfiguration: Fahrrad, Laufband, etc. pro Patient
//

import Foundation
import SwiftData

@Model
public final class KGGWarmup {
    @Attribute(.unique) public var id: UUID
    
    public var patientId: UUID
    public var type: String  // "Fahrrad", "Laufband", etc. (WarmupType.rawValue)
    public var duration: Int  // Minuten
    public var intensity: String  // "Widerstand Level 3" oder "4 km/h"
    public var notes: String?
    public var order: Int = 0  // Reihenfolge
    
    public init(
        id: UUID = UUID(),
        patientId: UUID,
        type: String,
        duration: Int,
        intensity: String,
        notes: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.patientId = patientId
        self.type = type
        self.duration = duration
        self.intensity = intensity
        self.notes = notes
        self.order = order
    }
    
    // MARK: - Helpers
    
    public var displayText: String {
        "\(type) - \(duration) Min - \(intensity)"
    }
}
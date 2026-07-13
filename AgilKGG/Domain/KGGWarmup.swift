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
   
       public var level: Int?         // Stufe, z.B. Fahrrad-Widerstand, Beinpresse
       public var speedKmh: Double?   // Geschwindigkeit, z.B. Laufband (3,5 etc.)
       public var seatLevel: Int?     // Sitzhöhe als Stufe
       public var weight: Double?     // Gewicht, falls Gerät das braucht
       public var notes: String?
    public var order: Int = 0  // Reihenfolge
    
    public init(
        id: UUID = UUID(),
        patientId: UUID,
        type: String,
        duration: Int,
       
              level: Int? = nil,
              speedKmh: Double? = nil,
              seatLevel: Int? = nil,
              weight: Double? = nil,
              notes: String? = nil,
              order: Int = 0
          ) {
              self.id = id
              self.patientId = patientId
              self.type = type
              self.duration = duration
           
              self.level = level
              self.speedKmh = speedKmh
              self.seatLevel = seatLevel
              self.weight = weight
              self.notes = notes
              self.order = order
          }
    // MARK: - Helpers
    
    public var displayText: String {
           var parts = ["\(type)", "\(duration) Min"]
           if let level { parts.append("Stufe \(level)") }
           if let seatLevel { parts.append("Sitzhöhe \(seatLevel)") }
           if let speedKmh { parts.append("\(speedKmh) km/h") }
           if let weight { parts.append("\(weight) kg") }
           return parts.joined(separator: " - ")
       }
}

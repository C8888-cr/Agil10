//
//  KGGScannedWarmup.swift
//  Agil10
//
//  Created by Christiane Roth on 13.07.26.
//


//
//  KGGScannedWarmup.swift
//  Agil
//
//  Domain Entity: Ein zugewiesenes Warmup beim Patienten.
//  Rein informative Anzeige, keine SwiftData-Abhängigkeiten.
//

import Foundation

public struct KGGScannedWarmup: Identifiable {

    public let id: UUID
    public let type: String
    public let duration: Int
    public let level: Int?
    public let seatLevel: Int?
    public let speedKmh: Double?
    public let weight: Double?
    public let notes: String?
    public let order: Int

    public let scannedAt: Date
    public let expiresAt: Date

    public var isVisible: Bool {
        Date() < expiresAt
    }

    public var displayText: String {
        var parts = ["\(duration) Min"]
        if let level { parts.append("Stufe \(level)") }
        if let seatLevel { parts.append("Sitzhöhe Stufe \(seatLevel)") }
        if let speedKmh { parts.append("\(speedKmh) km/h") }
        if let weight { parts.append("\(weight) kg") }
        return parts.joined(separator: " · ")
    }

    public init(
        id: UUID = UUID(),
        type: String,
        duration: Int,
        level: Int? = nil,
        seatLevel: Int? = nil,
        speedKmh: Double? = nil,
        weight: Double? = nil,
        notes: String? = nil,
        order: Int = 0,
        scannedAt: Date = Date(),
        expiresAt: Date
    ) {
        self.id = id
        self.type = type
        self.duration = duration
        self.level = level
        self.seatLevel = seatLevel
        self.speedKmh = speedKmh
        self.weight = weight
        self.notes = notes
        self.order = order
        self.scannedAt = scannedAt
        self.expiresAt = expiresAt
    }
}
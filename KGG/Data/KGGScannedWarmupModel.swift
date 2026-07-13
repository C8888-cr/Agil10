//
//  KGGScannedWarmupModel.swift
//  Agil10
//
//  Created by Christiane Roth on 13.07.26.
//


//
//  KGGScannedWarmupModel.swift
//  Agil
//
//  SwiftData @Model für persistente Speicherung des Patienten-Warmups.
//

import SwiftData
import Foundation

@Model
final class KGGScannedWarmupModel {

    @Attribute(.unique) var id: UUID = UUID()

    var type: String
    var duration: Int
    var level: Int?
    var seatLevel: Int?
    var speedKmh: Double?
    var weight: Double?
    var notes: String?
    var order: Int = 0

    var scannedAt: Date
    var expiresAt: Date

    init(
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

    func toDomain() -> KGGScannedWarmup {
        KGGScannedWarmup(
            id: id,
            type: type,
            duration: duration,
            level: level,
            seatLevel: seatLevel,
            speedKmh: speedKmh,
            weight: weight,
            notes: notes,
            order: order,
            scannedAt: scannedAt,
            expiresAt: expiresAt
        )
    }
}

extension KGGScannedWarmupModel {
    static func from(_ entity: KGGScannedWarmup) -> KGGScannedWarmupModel {
        KGGScannedWarmupModel(
            id: entity.id,
            type: entity.type,
            duration: entity.duration,
            level: entity.level,
            seatLevel: entity.seatLevel,
            speedKmh: entity.speedKmh,
            weight: entity.weight,
            notes: entity.notes,
            order: entity.order,
            scannedAt: entity.scannedAt,
            expiresAt: entity.expiresAt
        )
    }
}
//
//  KGGCategory.swift
//  AgilKGG
//
//  Flexibles Kategorie-System: feste Kategorien, wachsende Werte,
//  jede Kategorie optional zweistufig (Wert -> Unterwert).
//

import Foundation
import SwiftData

/// Die festen Kategorie-Typen.
public enum KGGCategoryType: String, CaseIterable, Codable, Identifiable {
    case muskel = "Muskel"
    case gelenk = "Gelenk"
    case geraet = "Trainingsgerät"
    case bewegungsrichtung = "Bewegungsrichtung"

    public var id: String { rawValue }
}

/// Ein gespeicherter Kategorie-Wert.
@Model
public final class KGGCategoryValue {
    @Attribute(.unique) public var id: UUID
    public var categoryRaw: String
    public var value: String
    public var parentValue: String?
    public var praxisId: UUID
    public var createdAt: Date

    public var category: KGGCategoryType? {
        KGGCategoryType(rawValue: categoryRaw)
    }

    public init(
        id: UUID = UUID(),
        category: KGGCategoryType,
        value: String,
        parentValue: String? = nil,
        praxisId: UUID
    ) {
        self.id = id
        self.categoryRaw = category.rawValue
        self.value = value
        self.parentValue = parentValue
        self.praxisId = praxisId
        self.createdAt = Date()
    }
}

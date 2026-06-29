//
//  KGGCategory.swift
//  AgilKGG
//
//  Flexibles Kategorie-System: feste Kategorien, wachsende Werte,
//  jede Kategorie optional zweistufig (Wert → Unterwert).
//

import Foundation
import SwiftData

/// Die festen Kategorie-Typen. Erweiterbar durch Ergänzen hier.
public enum KGGCategoryType: String, CaseIterable, Codable, Identifiable {
    case muskel = "Muskel"
    case gelenk = "Gelenk"
    case geraet = "Trainingsgerät"
    case bewegung = "Bewegung"

    public var id: String { rawValue }
}

/// Ein gespeicherter Kategorie-Wert (wächst pro Praxis).
/// parentValue = optionaler Oberwert (zweite Stufe).
@Model
public final class KGGCategoryValue {
    @Attribute(.unique) public var id: UUID
    public var categoryRaw: String      // KGGCategoryType.rawValue
    public var value: String            // z.B. "Schulter", "IRO"
    public var parentValue: String?     // z.B. "Schulter" für Unterwert "IRO"
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

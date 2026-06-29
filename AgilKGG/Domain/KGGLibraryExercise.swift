//
//  KGGLibraryExercise.swift
//  AgilKGG
//
//  Praxis-Übungsbibliothek: vorgefertigte KGG-Übungen.
//  Video verschlüsselt at-rest, Schlüssel in Keychain (Envelope).
//  Kategorien flexibel (optional zweistufig).
//

import Foundation
import SwiftData

@Model
public final class KGGLibraryExercise {
    @Attribute(.unique) public var id: UUID

    // Beschreibung
    public var title: String
    public var notes: String?

    // Praxis-Zuordnung
    public var praxisId: UUID

    // Gewählte Kategorie-Werte (je 1 pro Kategorie, optional + Unterwert)
    public var muskel: String?
    public var muskelSub: String?
    public var gelenk: String?
    public var gelenkSub: String?
    public var geraet: String?
    public var geraetSub: String?
    public var bewegung: String?
    public var bewegungSub: String?

    // Verschlüsseltes Video
    public var encryptedFileName: String?
    public var keychainKeyAccount: String?
    public var hasVideo: Bool = false
    public var thumbnailData: Data?

    // Timing
    public var createdAt: Date
    public var lastModified: Date

    public init(
        id: UUID = UUID(),
        title: String,
        praxisId: UUID,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.praxisId = praxisId
        self.notes = notes
        self.createdAt = Date()
        self.lastModified = Date()
    }

    public var subtitle: String {
        [muskel, gelenk, geraet, bewegung]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

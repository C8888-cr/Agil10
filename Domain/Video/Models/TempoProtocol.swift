//
//  TempoProtocol.swift
//  Agil10.0
//
//  Created by Christiane Roth on 19.04.26.
//


//
//  TempoProtocol.swift
//  Agil
//
//  Tempo-Protokoll für Kraft-Übungen im Expertenmodus.
//  Definiert die Ausführungsgeschwindigkeit (konzentrisch/halten/exzentrisch)
//  sowie Sätze, Wiederholungen und Pausenzeit.
//

import SwiftData
import Foundation

@Model
final class TempoProtocol {
    @Attribute(.unique) var id: UUID = UUID()
    
    // MARK: - Tempo (in Sekunden)
    /// Konzentrische Phase (z.B. Hochheben beim Bizeps-Curl)
    var concentricSec: Int
    /// Statische Haltezeit am Ende der konzentrischen Phase
    var holdSec: Int
    /// Exzentrische Phase (z.B. Ablassen beim Bizeps-Curl — langsam für Hypertrophie)
    var eccentricSec: Int
    
    // MARK: - Volumen
    var sets: Int
    var reps: Int
    /// Pause zwischen den Sätzen (in Sekunden)
    var restBetweenSetsSec: Int
    
    // MARK: - Subtyp
    /// Bei .isometric wird nur gehalten — `concentricSec` wird dann als Haltezeit interpretiert,
    /// `eccentricSec` und `holdSec` werden ignoriert.
    var subtypeRaw: String = ExerciseSubtype.dynamic.rawValue
    
    var subtype: ExerciseSubtype {
        get { ExerciseSubtype(rawValue: subtypeRaw) ?? .dynamic }
        set { subtypeRaw = newValue.rawValue }
    }
    
    // MARK: - Computed
    
    /// Gesamtdauer eines einzelnen Reps in Sekunden (nur dynamisch)
    var cycleDurationSec: Int {
        subtype == .dynamic
            ? concentricSec + holdSec + eccentricSec
            : concentricSec
    }
    
    /// Gesamtdauer des gesamten Protokolls inkl. Pausen
    var totalDurationSec: Int {
        let workPerSet = cycleDurationSec * reps
        let totalWork = workPerSet * sets
        let totalRest = restBetweenSetsSec * max(0, sets - 1)
        return totalWork + totalRest
    }
    
    // MARK: - Init
    
    init(
        concentricSec: Int = 2,
        holdSec: Int = 0,
        eccentricSec: Int = 3,
        sets: Int = 3,
        reps: Int = 12,
        restBetweenSetsSec: Int = 60,
        subtype: ExerciseSubtype = .dynamic
    ) {
        self.concentricSec = concentricSec
        self.holdSec = holdSec
        self.eccentricSec = eccentricSec
        self.sets = sets
        self.reps = reps
        self.restBetweenSetsSec = restBetweenSetsSec
        self.subtypeRaw = subtype.rawValue
    }
}
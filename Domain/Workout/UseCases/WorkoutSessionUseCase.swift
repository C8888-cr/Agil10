//
//  WorkoutSessionUseCase.swift
//  Agil10.0
//
//  Created by Christiane Roth on 19.04.26.
//


//
//  WorkoutSessionUseCase.swift
//  Agil
//
//  Steuert den Ablauf einer Expertenmodus-Trainingssession.
//  Pur Swift, ohne SwiftUI-Abhängigkeit. State-Machine.
//

import Foundation
import Combine

@MainActor
final class WorkoutSessionUseCase: ObservableObject {
    
    // MARK: - Published State
    @Published private(set) var state: WorkoutSessionState = .idle
    
    // MARK: - Configuration
    let protocolSnapshot: TempoProtocolSnapshot
    
    // MARK: - Internal
    private var phaseStartTime: TimeInterval = 0
    private var restStartTime: TimeInterval = 0
    private var currentSetIndex: Int = 0    // 0-indexiert intern
    private var currentRepIndex: Int = 0    // 0-indexiert intern
    private var timer: Timer?
    private var peakTriggeredThisCycle: Bool = false
    
    // Wie oft der State aktualisiert wird (50ms = flüssige Balken-Animation bei geringer CPU-Last)
    private let tickInterval: TimeInterval = 0.05
    
    // MARK: - Init
    
    init(protocolSnapshot: TempoProtocolSnapshot) {
        self.protocolSnapshot = protocolSnapshot
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Public Commands
    
    /// Startet den nächsten Satz (vom idle- oder resting-State aus)
    func startNextSet() {
        guard case .idle = state ,
              currentSetIndex < protocolSnapshot.sets else {
            if case .resting = state {
                // Pause skippen → direkt Satz starten
                beginWorkingSet()
            }
            return
        }
        beginWorkingSet()
    }
    
    /// Bricht die aktuelle Session ab und setzt zurück
    func abort() {
        stopTimer()
        currentSetIndex = 0
        currentRepIndex = 0
        state = .idle
    }
    
    /// Beendet die Pause vorzeitig und startet den nächsten Satz
    func skipRest() {
        guard case .resting = state else { return }
        beginWorkingSet()
    }
    
    // MARK: - Private State Transitions
    
    private func beginWorkingSet() {
        currentRepIndex = 0
        phaseStartTime = now()
        startTimer()
        tick() // Sofort initialen State setzen
    }
    
    private func finishCurrentSet() {
        stopTimer()
        currentSetIndex += 1
        
        if currentSetIndex >= protocolSnapshot.sets {
            state = .done
            return
        }
        
        // Pause starten
        restStartTime = now()
        startTimer()
        tickRest()
    }
    
    private func finishSession() {
        stopTimer()
        state = .done
    }
    
    // MARK: - Timer Loop
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if case .resting = self.state {
                    self.tickRest()
                } else {
                    self.tick()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Tick: Arbeitsphase
    
    private func tick() {
        let elapsed = now() - phaseStartTime
        let cycleDur = Double(protocolSnapshot.cycleDurationSec)
        
        // Zyklus fertig? Zum nächsten Rep-Start (nur Timer-Reset, currentRepIndex wurde schon beim Peak erhöht)
        if elapsed >= cycleDur {
            if currentRepIndex >= protocolSnapshot.reps {
                finishCurrentSet()
                return
            }
            phaseStartTime = now()
            return tick()
        }
        
        let (phase, phaseElapsed, phaseDuration) = computePhase(elapsed: elapsed)
        let progress = phaseDuration > 0 ? min(1.0, phaseElapsed / phaseDuration) : 1.0
        let remaining = max(0, phaseDuration - phaseElapsed)
        
        // Peak erreicht → Rep hochzählen (passiert einmal pro Zyklus am Ende der konz-Phase)
        if phase == .concentric && progress > 0.95 && !peakTriggeredThisCycle {
            peakTriggeredThisCycle = true
            currentRepIndex += 1
            
            if currentRepIndex >= protocolSnapshot.reps {
                // Noch die Runter-Phase zu Ende spielen, dann finishen — hier nur flaggen
            }
        }
        
        // Beim Start der konz-Phase: Flag zurücksetzen
        if phase == .concentric && progress < 0.05 {
            peakTriggeredThisCycle = false
        }
        
        state = .working(SetProgress(
            currentSet: currentSetIndex + 1,
            totalSets: protocolSnapshot.sets,
            currentRep: currentRepIndex,
            totalReps: protocolSnapshot.reps,
            phase: phase,
            phaseTimeRemaining: remaining,
            phaseProgress: progress
        ))
    }
    
    /// Entscheidet in welcher Phase (konz/halt/exz) wir gerade sind und wie weit
    private func computePhase(elapsed: Double) -> (RepPhase, Double, Double) {
        // Isometrisch: Nur eine Phase, ganzer Cycle ist "halten"
        if protocolSnapshot.subtype == .isometric {
            return (.isometric, elapsed, Double(protocolSnapshot.concentricSec))
        }
        
        let conc = Double(protocolSnapshot.concentricSec)
        let hold = Double(protocolSnapshot.holdSec)
        let ecc = Double(protocolSnapshot.eccentricSec)
        
        if elapsed < conc {
            return (.concentric, elapsed, conc)
        } else if elapsed < conc + hold {
            return (.hold, elapsed - conc, hold)
        } else {
            return (.eccentric, elapsed - conc - hold, ecc)
        }
    }
    
    // MARK: - Tick: Pause
    
    private func tickRest() {
        let elapsed = now() - restStartTime
        let total = Double(protocolSnapshot.restBetweenSetsSec)
        let remaining = max(0, total - elapsed)
        
        if remaining <= 0 {
            beginWorkingSet()
            return
        }
        
        state = .resting(RestProgress(
            completedSet: currentSetIndex,
            totalSets: protocolSnapshot.sets,
            secondsRemaining: Int(ceil(remaining)),
            totalSeconds: protocolSnapshot.restBetweenSetsSec
        ))
    }
    
    // MARK: - Helpers
    
    private func now() -> TimeInterval {
        Date().timeIntervalSinceReferenceDate
    }
}

// MARK: - Snapshot

/// Immutabler Snapshot eines TempoProtocol, damit der UseCase unabhängig vom SwiftData-Model arbeitet.
/// Wichtig für Testbarkeit (kein ModelContainer nötig) und Thread-Sicherheit.
struct TempoProtocolSnapshot: Equatable {
    let concentricSec: Int
    let holdSec: Int
    let eccentricSec: Int
    let sets: Int
    let reps: Int
    let restBetweenSetsSec: Int
    let subtype: ExerciseSubtype
    
    var cycleDurationSec: Int {
        subtype == .dynamic
            ? concentricSec + holdSec + eccentricSec
            : concentricSec
    }
}

// MARK: - Snapshot aus TempoProtocol bauen

extension TempoProtocolSnapshot {
    init(from model: TempoProtocol) {
        self.concentricSec = model.concentricSec
        self.holdSec = model.holdSec
        self.eccentricSec = model.eccentricSec
        self.sets = model.sets
        self.reps = model.reps
        self.restBetweenSetsSec = model.restBetweenSetsSec
        self.subtype = model.subtype
    }
    
    /// 🆕 Snapshot mit User-Overrides aus dem Schedule
    init(
        from model: TempoProtocol,
        setsOverride: Int?,
        repsOverride: Int?,
        restOverride: Int?
    ) {
        self.concentricSec = model.concentricSec
        self.holdSec = model.holdSec
        self.eccentricSec = model.eccentricSec
        self.sets = setsOverride ?? model.sets
        self.reps = repsOverride ?? model.reps
        self.restBetweenSetsSec = restOverride ?? model.restBetweenSetsSec
        self.subtype = model.subtype
    }
}

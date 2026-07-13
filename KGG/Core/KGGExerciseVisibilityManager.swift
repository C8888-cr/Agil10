//
//  KGGExerciseVisibilityManager.swift
//  Agil
//
//  Verwaltet die Sichtbarkeit von KGG-Übungen über Zeit.
//  - Nach QR-Scan: 60min sichtbar
//  - Nach 60min: "Glückwunsch"-Screen, nicht mehr sichtbar
//  - Videos bleiben lokal gespeichert
//

import Foundation
import Combine
import AgilCore

@MainActor
public final class KGGExerciseVisibilityManager: ObservableObject {
    
    @Published public private(set) var state: VisibilityState = .noKGG
    @Published public private(set) var timeRemainingSeconds: Int = 0
    
    private var timer: Timer?
    private var completionTime: Date?
    
    public enum VisibilityState {
        case noKGG                 // Kein aktiver KGG-Scan
        case visible               // Übungen sichtbar (noch < 60min)
        case completed             // 60min vorbei → "Glückwunsch"
    }
    
    public init() {}
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Public API
    
    public func startSession() {
        completionTime = Date().addingTimeInterval(
            TimeInterval(KGGConfiguration.exerciseVisibilityDurationSeconds)
        )
        state = .visible
        startTimer()
    }
    
    public func markCompleted() {
            timer?.invalidate()
            timer = nil
            state = .completed
        }
        
        /// Verarbeitet einen gescannten Start-Token. Gibt `false` zurück, wenn
        /// dieser Token bereits einmal verwendet wurde (abfotografierter/alter
        /// QR) — dann wird NICHT freigeschaltet.
        public func consumeStartToken(_ token: KGGStartSessionToken) -> Bool {
            let key = "KGGLastStartTokenId"
            let lastId = UserDefaults.standard.string(forKey: key)
            guard lastId != token.id.uuidString else {
                return false
            }
            UserDefaults.standard.set(token.id.uuidString, forKey: key)
            startSession()
            return true
        }
    
    public func reset() {
        timer?.invalidate()
        timer = nil
        state = .noKGG
        completionTime = nil
        timeRemainingSeconds = 0
    }
    
    public func checkExistingSession() {
        guard let completion = completionTime else {
            state = .noKGG
            return
        }
        
        let remaining = Int(completion.timeIntervalSinceNow)
        if remaining > 0 {
            state = .visible
            timeRemainingSeconds = remaining
            startTimer()
        } else {
            state = .completed
        }
    }
    
    // MARK: - Private
    
    private func startTimer() {
        timer?.invalidate()
        updateTimeRemaining()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTimeRemaining()
            }
        }
    }
    
    private func updateTimeRemaining() {
        guard let completion = completionTime else { return }
        
        let remaining = Int(completion.timeIntervalSinceNow)
        
        if remaining <= 0 {
            timer?.invalidate()
            timer = nil
            state = .completed
            timeRemainingSeconds = 0
        } else {
            timeRemainingSeconds = remaining
        }
    }
}

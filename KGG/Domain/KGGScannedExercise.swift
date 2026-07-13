//
//  KGGScannedExercise.swift
//  Agil
//
//  Domain Entity: Eine gescannte KGG-Übung mit allen Trainingsdaten.
//  Keine SwiftData-Abhängigkeiten.
//

import Foundation
import AgilCore

public struct KGGScannedExercise: Identifiable {
    
    public let id: UUID
    public let exerciseId: UUID
    public let exerciseTitle: String
    public let videoFileName: String
    public let isVideoDownloaded: Bool
    
    public let reps: Int
    public let sets: Int
    public let weightKg: Double
    
    public let concentricSec: Int
    public let holdSec: Int
    public let eccentricSec: Int
    public let restBetweenSetsSec: Int
        public let level: Int?
        public let seatLevel: Int?
        public let notes: String?
        
        public let scannedAt: Date
    public let expiresAt: Date
    
    public let isCompleted: Bool
    public let completedAt: Date?
    
    // MARK: - Computed
    
    public var isVisible: Bool {
        Date() < expiresAt && !isCompleted
    }
    
    public var secondsUntilExpiry: Int {
        Int(expiresAt.timeIntervalSinceNow)
    }
    
    public var cycleDurationSec: Int {
        concentricSec + holdSec + eccentricSec
    }
    
    public var estimatedTotalDurationSec: Int {
        let workTime = sets * reps * cycleDurationSec
        let restTime = restBetweenSetsSec * max(0, sets - 1)
        return workTime + restTime
    }
    
    public var tempo: String {
        "\(concentricSec)-\(holdSec)-\(eccentricSec)"
    }
    
    // MARK: - Init
    
    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseTitle: String,
        videoFileName: String,
        isVideoDownloaded: Bool = false,
        reps: Int,
        sets: Int,
        weightKg: Double,
        concentricSec: Int,
        holdSec: Int,
        eccentricSec: Int,
               restBetweenSetsSec: Int,
               level: Int? = nil,
               seatLevel: Int? = nil,
               notes: String? = nil,
               scannedAt: Date = Date(),
        expiresAt: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseTitle = exerciseTitle
        self.videoFileName = videoFileName
        self.isVideoDownloaded = isVideoDownloaded
        self.reps = reps
        self.sets = sets
        self.weightKg = weightKg
        self.concentricSec = concentricSec
        self.holdSec = holdSec
        self.eccentricSec = eccentricSec
        
        self.restBetweenSetsSec = restBetweenSetsSec
               self.level = level
               self.seatLevel = seatLevel
               self.notes = notes
               self.scannedAt = scannedAt
        
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.expiresAt = expiresAt
    }
}

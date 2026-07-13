//
//  KGGScannedExerciseModel.swift
//  Agil
//
//  SwiftData @Model für persistente Speicherung.
//

import SwiftData
import Foundation

@Model
final class KGGScannedExerciseModel {
    
    @Attribute(.unique) var id: UUID = UUID()
    
    var exerciseId: UUID
    var exerciseTitle: String
    var videoFileName: String
    var isVideoDownloaded: Bool = false
    
    var reps: Int
    var sets: Int
    var weightKg: Double
    
    var concentricSec: Int
    var holdSec: Int
    var eccentricSec: Int
    var restBetweenSetsSec: Int
    
    var scannedAt: Date
    var expiresAt: Date
    
    var isCompleted: Bool = false
    var completedAt: Date?
    
    init(
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
        self.scannedAt = scannedAt
        self.expiresAt = expiresAt
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
    
    func toDomain() -> KGGScannedExercise {
        KGGScannedExercise(
            id: id,
            exerciseId: exerciseId,
            exerciseTitle: exerciseTitle,
            videoFileName: videoFileName,
            isVideoDownloaded: isVideoDownloaded,
            reps: reps,
            sets: sets,
            weightKg: weightKg,
            concentricSec: concentricSec,
            holdSec: holdSec,
            eccentricSec: eccentricSec,
            restBetweenSetsSec: restBetweenSetsSec,
            scannedAt: scannedAt,
            expiresAt: expiresAt,
            isCompleted: isCompleted,
            completedAt: completedAt
        )
    }
}

extension KGGScannedExerciseModel {
    static func from(_ entity: KGGScannedExercise) -> KGGScannedExerciseModel {
        KGGScannedExerciseModel(
            id: entity.id,
            exerciseId: entity.exerciseId,
            exerciseTitle: entity.exerciseTitle,
            videoFileName: entity.videoFileName,
            isVideoDownloaded: entity.isVideoDownloaded,
            reps: entity.reps,
            sets: entity.sets,
            weightKg: entity.weightKg,
            concentricSec: entity.concentricSec,
            holdSec: entity.holdSec,
            eccentricSec: entity.eccentricSec,
            restBetweenSetsSec: entity.restBetweenSetsSec,
            scannedAt: entity.scannedAt,
            expiresAt: entity.expiresAt,
            isCompleted: entity.isCompleted,
            completedAt: entity.completedAt
        )
    }
}

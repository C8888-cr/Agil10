//
//  KGGPatient.swift
//  AgilKGG
//
//  Lokales Datenmodell für einen Patienten in der Therapeuten-App.
//  Speichert Nummer (aus TheOrg) und aktuelle Übungs-Zuordnung.
//  Nicht identisch mit Patient-Model der Patienten-App.
//

import Foundation
import SwiftData
import AgilCore

@Model
final class KGGPatient {
    @Attribute(.unique) var patientNumber: String  // "Pat1", "Pat2", etc.
    
    var currentAssignments: [ExerciseAssignment] = []
    var lastModified: Date = Date()
    
    init(patientNumber: String) {
        self.patientNumber = patientNumber
        self.currentAssignments = []
        self.lastModified = Date()
    }
    
    /// Übung hinzufügen oder ersetzen (nach exerciseId)
    func addOrUpdateAssignment(_ assignment: ExerciseAssignment) {
        if let index = currentAssignments.firstIndex(where: { $0.exerciseId == assignment.exerciseId }) {
            currentAssignments[index] = assignment
        } else {
            currentAssignments.append(assignment)
        }
        lastModified = Date()
    }
    
    /// Übung entfernen
    func removeAssignment(exerciseId: UUID) {
        currentAssignments.removeAll { $0.exerciseId == exerciseId }
        lastModified = Date()
    }
    
    /// QR-Payload für aktuellen Stand
    func generateQRPayload() -> QRPayload {
        QRPayload(
            version: 1,
            issuedAt: Date(),
            assignments: currentAssignments
        )
    }
}

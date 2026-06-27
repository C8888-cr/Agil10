//
//  KGGTherapistViewModel.swift
//  AgilKGG
//
//  Zentrale Business-Logic für Therapeuten-App:
//  - Patienten-Management (lokal in SwiftData)
//  - Video-Library (aus Documents/agil-kgg-videos/)
//  - Übungs-Zuordnung (Reps/Gewichte editierbar)
//  - QR-Generierung
//
//  Clean Architecture: ViewModel als Coordinator zwischen UI + Data Layer.
//

import Foundation
import SwiftData
import CryptoKit
import AgilCore
import Combine

@MainActor
class KGGTherapistViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var patients: [KGGPatient] = []
    @Published var selectedPatient: KGGPatient?
    @Published var availableVideos: [KGGVideoInfo] = []
    @Published var qrPayload: QRPayload?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let qrCoder = QRCoder()
    
    // MARK: - Init
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadPatients()
            await loadVideos()
        }
    }
    
    // MARK: - Patient Management
    
    /// Neuen Patienten hinzufügen (Nummer aus TheOrg eingeben)
    func addPatient(number: String) throws {
        let trimmed = number.trimmingCharacters(in: .whitespaces).uppercased()
        
        guard !trimmed.isEmpty else {
            throw KGGTherapistError.patientNumberEmpty
        }
        
        guard !patients.contains(where: { $0.patientNumber == trimmed }) else {
            throw KGGTherapistError.patientAlreadyExists
        }
        
        let newPatient = KGGPatient(patientNumber: trimmed)
        modelContext.insert(newPatient)
        try modelContext.save()
        
        patients.append(newPatient)
        selectedPatient = newPatient
    }
    
    /// Patienten löschen
    func deletePatient(_ patient: KGGPatient) throws {
        modelContext.delete(patient)
        try modelContext.save()
        patients.removeAll { $0.patientNumber == patient.patientNumber }
        if selectedPatient == patient {
            selectedPatient = patients.first
        }
    }
    
    /// Patienten neu laden (z.B. nach Datenbankänderung)
    private func loadPatients() async {
        do {
            let descriptor = FetchDescriptor<KGGPatient>()
            patients = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Patienten konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Video Library
    
    /// Videos aus Documents/agil-kgg-videos/ laden
    private func loadVideos() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let videosDir = documentsURL.appendingPathComponent("agil-kgg-videos")
            
            // Verzeichnis erstellen, falls nicht vorhanden
            try? FileManager.default.createDirectory(at: videosDir, withIntermediateDirectories: true)
            
            // .agkv Dateien laden (verschlüsselte KGG-Videos)
            let fileURLs = try FileManager.default.contentsOfDirectory(at: videosDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "agkv" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            
            availableVideos = fileURLs.map { url in
                KGGVideoInfo(
                    videoId: UUID(),  // In echtem System: ID aus Dateiname oder Metadaten
                    title: url.deletingPathExtension().lastPathComponent,
                    fileURL: url,
                    encryptionKey: SymmetricKey(size: .bits256)  // Placeholder – später aus Keychain
                )
            }
        } catch {
            errorMessage = "Videos konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Exercise Assignment (Reps/Gewichte)
    
    /// Übung zu Patient hinzufügen/aktualisieren
    func assignExercise(
        to patient: KGGPatient,
        videoId: UUID,
        reps: Int,
        weight: Double,
        videoKey: Data
    ) throws {
        guard reps > 0 else {
            throw KGGTherapistError.invalidReps
        }
        
        guard weight >= 0 else {
            throw KGGTherapistError.invalidWeight
        }
        
        let assignment = ExerciseAssignment(
            exerciseId: videoId,
            reps: reps,
            weight: weight,
            videoKey: videoKey
        )
        
        patient.addOrUpdateAssignment(assignment)
        try modelContext.save()
    }
    
    /// Übung von Patient entfernen
    func removeExercise(from patient: KGGPatient, videoId: UUID) throws {
        patient.removeAssignment(exerciseId: videoId)
        try modelContext.save()
    }
    
    /// Reps/Gewicht einer bestehenden Übung aktualisieren
    func updateExerciseParams(
        for patient: KGGPatient,
        videoId: UUID,
        newReps: Int,
        newWeight: Double
    ) throws {
        guard newReps > 0 else {
            throw KGGTherapistError.invalidReps
        }
        
        guard newWeight >= 0 else {
            throw KGGTherapistError.invalidWeight
        }
        
        if let index = patient.currentAssignments.firstIndex(where: { $0.exerciseId == videoId }) {
            var assignment = patient.currentAssignments[index]
            assignment = ExerciseAssignment(
                exerciseId: assignment.exerciseId,
                reps: newReps,
                weight: newWeight,
                videoKey: assignment.videoKey
            )
            patient.currentAssignments[index] = assignment
            try modelContext.save()
        }
    }
    
    // MARK: - QR Generation
    
    /// QR-Payload aus aktueller Patient-Zuordnung generieren
    func generateQRForPatient(_ patient: KGGPatient) throws -> QRPayload {
        let payload = patient.generateQRPayload()
        
        guard !payload.assignments.isEmpty else {
            throw KGGTherapistError.noAssignments
        }
        
        self.qrPayload = payload
        return payload
    }
    
    /// QR-Inhalt als Base64-String (zum Codieren ins Bild)
    func encodeQRContent() throws -> String {
        guard let payload = qrPayload else {
            throw KGGTherapistError.noQRPayload
        }
        
        return try qrCoder.encode(payload)
    }
    
    // MARK: - Error Handling
    
    enum KGGTherapistError: LocalizedError {
        case patientNumberEmpty
        case patientAlreadyExists
        case invalidReps
        case invalidWeight
        case noAssignments
        case noQRPayload
        
        var errorDescription: String? {
            switch self {
            case .patientNumberEmpty:
                return "Patientennummer darf nicht leer sein."
            case .patientAlreadyExists:
                return "Patient existiert bereits."
            case .invalidReps:
                return "Wiederholungen müssen > 0 sein."
            case .invalidWeight:
                return "Gewicht darf nicht negativ sein."
            case .noAssignments:
                return "Patient hat keine Übungen zugewiesen."
            case .noQRPayload:
                return "Kein QR-Payload generiert."
            }
        }
    }
}

// MARK: - Supporting Types

/// Info über ein KGG-Video aus der Bibliothek
struct KGGVideoInfo: Identifiable {
    let videoId: UUID
    let title: String
    let fileURL: URL
    let encryptionKey: SymmetricKey
    
    var id: UUID { videoId }
}

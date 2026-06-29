//
//  KGGPatientListViewModel.swift
//  AgilKGG
//
//  Patient-Liste: Laden, Suchen, Hinzufügen, Löschen
//

import Foundation
import SwiftData
import Combine

@MainActor
final class KGGPatientListViewModel: ObservableObject {
    @Published var allPatients: [KGGPatient] = []
    @Published var filteredPatients: [KGGPatient] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPatient: KGGPatient?
    
    private let modelContext: ModelContext
    private let praxisId: UUID  // ← UUID statt String
    
    init(modelContext: ModelContext, praxisId: UUID) {  // ← UUID
        self.modelContext = modelContext
        self.praxisId = praxisId
    }
    
    // MARK: - Load Patients
    
    func loadPatients() {
        isLoading = true
        defer { isLoading = false }
        
        do {
            var descriptor = FetchDescriptor<KGGPatient>()
            descriptor.predicate = #Predicate<KGGPatient> { $0.praxisId == praxisId }
            descriptor.sortBy = [SortDescriptor(\KGGPatient.patientNumber)]
            
            allPatients = try modelContext.fetch(descriptor)
            applySearch()
        } catch {
            errorMessage = "Patienten konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Search
    
    func applySearch() {
        if searchText.isEmpty {
            filteredPatients = allPatients
        } else {
            filteredPatients = allPatients.filter {
                $0.patientNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.diagnosis.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Add Patient
    
    func addPatient(number: String) throws {
        let trimmed = number.trimmingCharacters(in: .whitespaces).uppercased()
        
        guard !trimmed.isEmpty else {
            throw PatientError.emptyNumber
        }
        
        guard !allPatients.contains(where: { $0.patientNumber == trimmed }) else {
            throw PatientError.alreadyExists
        }
        
        let newPatient = KGGPatient(
            patientNumber: trimmed,
            praxisId: praxisId
        )
        
        modelContext.insert(newPatient)
        try modelContext.save()
        
        allPatients.append(newPatient)
        selectedPatient = newPatient
        applySearch()
    }
    
    // MARK: - Delete Patient
    
    func deletePatient(_ patient: KGGPatient) throws {
        modelContext.delete(patient)
        try modelContext.save()
        
        allPatients.removeAll { $0.id == patient.id }
        if selectedPatient?.id == patient.id {
            selectedPatient = allPatients.first
        }
        applySearch()
    }
    
    // MARK: - Update Patient
    
    func updatePatient(
        _ patient: KGGPatient,
        diagnosis: String,
        movementLimitation: String,
        restrictions: String,
        notes: String
    ) throws {
        patient.diagnosis = diagnosis
        patient.movementLimitation = movementLimitation
        patient.restrictions = restrictions
        patient.therapeutistNotes = notes
        patient.lastModified = Date()
        
        try modelContext.save()
    }
    
    // MARK: - Errors
    
    enum PatientError: LocalizedError {
        case emptyNumber
        case alreadyExists
        
        var errorDescription: String? {
            switch self {
            case .emptyNumber: return "Patientennummer darf nicht leer sein"
            case .alreadyExists: return "Patient existiert bereits"
            }
        }
    }
}

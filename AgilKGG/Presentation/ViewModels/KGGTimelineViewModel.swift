//
//  KGGTimelineViewModel.swift
//  AgilKGG
//
//  Timeline: Alle Änderungen einer Übung chronologisch anzeigen
//

import Foundation
import SwiftData
import Combine

@MainActor
final class KGGTimelineViewModel: ObservableObject {
    @Published var historyEntries: [KGGExerciseHistory] = []
    @Published var filteredEntries: [KGGExerciseHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedActionFilter: KGGExerciseHistory.HistoryAction?
    
    private let modelContext: ModelContext
    private let exerciseId: UUID
    private let patientId: UUID
    
    init(exerciseId: UUID, patientId: UUID, modelContext: ModelContext) {
        self.exerciseId = exerciseId
        self.patientId = patientId
        self.modelContext = modelContext
    }
    
    // MARK: - Load History
    
    func loadHistory() {
        isLoading = true
        defer { isLoading = false }
        
        let currentExerciseId = exerciseId  // ← Lokale Kopien für Predicate
        let currentPatientId = patientId
        
        do {
            let descriptor = FetchDescriptor<KGGExerciseHistory>(
                predicate: #Predicate { entry in
                    entry.exerciseId == currentExerciseId && entry.patientId == currentPatientId
                }
            )
            var finalDescriptor = descriptor
            finalDescriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
            
            historyEntries = try modelContext.fetch(finalDescriptor)
            applyFilters()
        } catch {
            errorMessage = "History konnte nicht geladen werden: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Filtering
    
    func applyFilters() {
        if let filter = selectedActionFilter {
            filteredEntries = historyEntries.filter { $0.action == filter }
        } else {
            filteredEntries = historyEntries
        }
    }
    
    func clearFilter() {
        selectedActionFilter = nil
        applyFilters()
    }
    
    // MARK: - Add History Entry
    
    func addEntry(
        action: KGGExerciseHistory.HistoryAction,
        changes: String,
        changedBy: String = "Therapeut",
        notes: String? = nil
    ) throws {
        let entry = KGGExerciseHistory(
            exerciseId: exerciseId,
            patientId: patientId,
            changedBy: changedBy,
            action: action,
            changes: changes,
            notes: notes
        )
        
        modelContext.insert(entry)
        try modelContext.save()
        
        historyEntries.append(entry)
        historyEntries.sort { $0.timestamp > $1.timestamp }
        applyFilters()
    }
    
    // MARK: - Computed Properties
    
    var allActions: [KGGExerciseHistory.HistoryAction] {
        [.created, .updated, .deleted, .paused, .resumed]
    }
    
    var groupedByDate: [String: [KGGExerciseHistory]] {
        Dictionary(grouping: filteredEntries) { entry in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "de_DE")
            formatter.dateStyle = .medium
            return formatter.string(from: entry.timestamp)
        }
    }
}

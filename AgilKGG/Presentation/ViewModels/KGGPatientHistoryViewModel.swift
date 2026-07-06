//
//  KGGPatientHistoryViewModel.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.07.26.
//


//
//  KGGPatientHistoryViewModel.swift
//  AgilKGG
//
//  Read-only ViewModel für Patienten-Historie.
//  Writes ausschließlich über KGGPatientDetailViewModel (Single Source of Truth).
//

import Foundation
import SwiftData
import Combine

@MainActor
final class KGGPatientHistoryViewModel: ObservableObject {

    // MARK: - Types

    struct DayGroup: Identifiable {
        let id: String  // Datum-String als stabile ID
        let date: String
        let entries: [KGGExerciseHistory]
    }

    // MARK: - State

    @Published private(set) var entries: [KGGExerciseHistory] = []
    @Published private(set) var isLoading = false

    let patientId: UUID
    let patientNumber: String

    private let modelContext: ModelContext
    private lazy var libraryRepository = KGGLibraryRepository(modelContext: modelContext)

    // MARK: - Init

    init(patientId: UUID, patientNumber: String, modelContext: ModelContext) {
        self.patientId = patientId
        self.patientNumber = patientNumber
        self.modelContext = modelContext
    }

    // MARK: - Load

    func load() {
        isLoading = true
        defer { isLoading = false }

        let id = patientId
        var descriptor = FetchDescriptor<KGGExerciseHistory>()
        descriptor.predicate = #Predicate<KGGExerciseHistory> { $0.patientId == id }
        descriptor.sortBy = [SortDescriptor(\KGGExerciseHistory.timestamp, order: .reverse)]
        entries = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Thumbnail (Read-only via Library)

    func thumbnail(for entry: KGGExerciseHistory) -> Data? {
        (try? libraryRepository.fetchExercise(id: entry.videoId))?.thumbnailData
    }
    // MARK: - Gruppierung

    var groupedByDate: [DayGroup] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .full

        var groups: [String: [KGGExerciseHistory]] = [:]
        var orderedKeys: [String] = []

        for entry in entries {
            let key = formatter.string(from: entry.timestamp)
            if groups[key] == nil { orderedKeys.append(key) }
            groups[key, default: []].append(entry)
        }

        return orderedKeys.map {
            DayGroup(id: $0, date: $0, entries: groups[$0] ?? [])
        }
    }
}

//
//  KGGLibraryViewModel.swift
//  AgilKGG
//
//  Single Source of Truth für Übungen, Filter und Kategorie-Werte.
//  Filter und Anlege-Formular lesen aus demselben published Cache —
//  neue Werte sind sofort überall sichtbar (Seeds + Praxis-eigene in einer Liste).
//

import Foundation
import SwiftData
import SwiftUI
import Combine
import AgilCore

@MainActor
final class KGGLibraryViewModel: ObservableObject {

    // MARK: - Published State

    @Published var exercises: [KGGLibraryExercise] = []
    @Published var isLoading = false
    @Published var isImporting = false
    @Published var errorMessage: String?

    @Published var searchText: String = ""

    /// Aktive Filter: Kategorie → gewählter Wert. Frei kombinierbar (UND-Verknüpfung).
    @Published var activeFilters: [KGGCategoryType: String] = [:]

    /// Alle Werte pro Kategorie (Seeds + Praxis-eigene, alphabetisch aus dem Repository).
    @Published private(set) var valueCache: [KGGCategoryType: [String]] = [:]

    private let repository: KGGLibraryRepository
    let praxisId: UUID

    init(modelContext: ModelContext, praxisId: UUID) {
        self.repository = KGGLibraryRepository(modelContext: modelContext)
        self.praxisId = praxisId

        seedCategoriesIfNeeded()
        reloadCategoryValues()
    }

    // MARK: - Übungen laden

    func load() {
        isLoading = true
        defer { isLoading = false }

        do {
            exercises = try repository.fetchExercises(praxisId: praxisId)
        } catch {
            errorMessage = "Übungen konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    // MARK: - Filterung

    var filteredExercises: [KGGLibraryExercise] {
        exercises.filter { ex in
            // 1) Freitext-Suche (satzzeichen-tolerant, siehe kggSearchKey)
            let query = searchText.kggSearchKey
            if !query.isEmpty {
                let haystack = [
                    ex.title,
                    ex.notes ?? "",
                    ex.muskel ?? "",
                    ex.gelenk ?? "",
                    ex.geraet ?? "",
                    ex.bewegung ?? "",
                    ex.subtitle
                ]
                .joined(separator: " ")
                .kggSearchKey

                if !haystack.contains(query) { return false }
            }

            // 2) Kategorie-Filter (alle aktiven müssen passen)
            for (cat, filterValue) in activeFilters {
                guard value(of: ex, for: cat) == filterValue else { return false }
            }

            return true
        }
    }

    /// Anzahl aktiver Filter — für das Badge im Filter-Header.
    var activeFilterCount: Int {
        activeFilters.count
    }

    private func value(of ex: KGGLibraryExercise, for cat: KGGCategoryType) -> String? {
        switch cat {
        case .muskel: return ex.muskel
        case .gelenk: return ex.gelenk
        case .geraet: return ex.geraet
        case .bewegungsrichtung: return ex.bewegung
        }
    }

    // MARK: - Filter setzen

    func setFilter(_ category: KGGCategoryType, value: String?) {
        if let value, !value.isEmpty {
            activeFilters[category] = value
        } else {
            activeFilters[category] = nil
        }
    }

    func resetFilters() {
        activeFilters = [:]
    }

    // MARK: - Kategorie-Werte (aus dem Cache, reaktiv)

    /// Alle Werte einer Kategorie (Seeds + Praxis-eigene in einer Liste).
    func categoryValues(_ category: KGGCategoryType) -> [String] {
        valueCache[category] ?? []
    }

    /// Lädt die Werte aller Kategorien neu in den published Cache.
    func reloadCategoryValues() {
        do {
            var values: [KGGCategoryType: [String]] = [:]
            for type in KGGCategoryType.allCases {
                values[type] = try repository
                    .fetchCategoryValues(category: type, praxisId: praxisId)
                    .map(\.value)
            }
            valueCache = values
        } catch {
            errorMessage = "Kategorien konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    /// Legt einen neuen Wert für diese Praxis an und aktualisiert den Cache —
    /// der Wert erscheint sofort in Filter UND Anlege-Formular.
    func addCategoryValue(_ category: KGGCategoryType, value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            _ = try repository.addCategoryValue(
                category: category,
                value: trimmed,
                parentValue: nil,
                praxisId: praxisId
            )
            reloadCategoryValues()
        } catch {
            errorMessage = "Kategorie-Wert konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    /// Löscht einen Praxis-eigenen Wert. Seeds sind nicht löschbar.
    /// Hinweis: Aktuell von keinem UI aufgerufen — bleibt für eine spätere
    /// "Kategorien verwalten"-Ansicht erhalten.
    func deleteCustomCategoryValue(_ value: String, for category: KGGCategoryType) {
        guard isCustomValue(value, for: category) else { return }

        do {
            let all = try repository.fetchCategoryValues(category: category, praxisId: praxisId)
            if let toDelete = all.first(where: { $0.value == value }) {
                try repository.deleteCategoryValue(id: toDelete.id)
                reloadCategoryValues()
            }
        } catch {
            errorMessage = "Kategorie konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }

    func isCustomValue(_ value: String, for category: KGGCategoryType) -> Bool {
        !KGGCategorySeeds.values(for: category).contains(value)
    }

    // MARK: - Übung anlegen / Video / Löschen

    @discardableResult
    func create(
        title: String,
        muskel: String?,
        gelenk: String?,
        geraet: String?,
        bewegung: String?,
        notes: String?
    ) -> KGGLibraryExercise? {
        do {
            let ex = try repository.createExercise(
                title: title,
                praxisId: praxisId,
                muskel: muskel, muskelSub: nil,
                gelenk: gelenk, gelenkSub: nil,
                geraet: geraet, geraetSub: nil,
                bewegung: bewegung, bewegungSub: nil,
                notes: notes
            )
            load()
            return ex
        } catch {
            errorMessage = "Übung konnte nicht angelegt werden: \(error.localizedDescription)"
            return nil
        }
    }

    func attachVideo(_ sourceURL: URL, to exercise: KGGLibraryExercise) async {
            isImporting = true
            defer { isImporting = false }

            do {
                try await repository.attachVideo(sourceURL: sourceURL, to: exercise)
            load()
        } catch {
            errorMessage = "Video konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    func delete(_ exercise: KGGLibraryExercise) {
        do {
            try repository.deleteExercise(exercise)
            load()
        } catch {
            errorMessage = "Löschen fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    // MARK: - Seeding (einmalig pro Praxis)

    func seedCategoriesIfNeeded() {
        for type in KGGCategoryType.allCases {
            let existing = (try? repository.fetchCategoryValues(category: type, praxisId: praxisId)) ?? []
            guard existing.isEmpty else { continue }

            for value in KGGCategorySeeds.values(for: type) {
                do {
                    _ = try repository.addCategoryValue(
                        category: type,
                        value: value,
                        parentValue: nil,
                        praxisId: praxisId
                    )
                } catch {
                    print("❌ Seed fehlgeschlagen [\(type.rawValue)] \(value): \(error)")
                }
            }
        }
    }
}

// MARK: - Such-Normalisierung

extension String {
    /// Normalisiert für die Suche: diakritikfrei, klein, ß→ss,
    /// Satzzeichen werden ignoriert ("ext." findet "ext").
    var kggSearchKey: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "ß", with: "ss")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

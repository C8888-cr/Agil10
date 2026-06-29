//
//  KGGLibraryViewModel.swift
//  AgilKGG
//
//  Übungsbibliothek: Laden, Anlegen mit Kategorien, Video verschlüsselt importieren,
//  Suche + Kategorie-Filter, wachsende Kategorie-Werte.
//

import Foundation
import SwiftData
import SwiftUI
import PhotosUI
import Combine
import AgilCore

@MainActor
final class KGGLibraryViewModel: ObservableObject {
    @Published var exercises: [KGGLibraryExercise] = []
    @Published var isLoading = false
    @Published var isImporting = false
    @Published var errorMessage: String?

    // Suche / Filter
    @Published var searchText: String = ""
    @Published var activeCategory: KGGCategoryType?      // nil = "Alle"
    @Published var activeValue: String?                   // gewählter Wert im Filter

    private let repository: KGGLibraryRepository
    let praxisId: UUID

    init(modelContext: ModelContext, praxisId: UUID) {
        self.repository = KGGLibraryRepository(modelContext: modelContext)
        self.praxisId = praxisId
    }

    // MARK: - Laden

    func load() {
        isLoading = true
        defer { isLoading = false }
        do {
            exercises = try repository.fetchExercises(praxisId: praxisId)
        } catch {
            errorMessage = "Übungen konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    // MARK: - Gefilterte Liste

    var filteredExercises: [KGGLibraryExercise] {
        exercises.filter { ex in
            // Textsuche
            if !searchText.isEmpty {
                let hit = ex.title.localizedCaseInsensitiveContains(searchText)
                    || ex.subtitle.localizedCaseInsensitiveContains(searchText)
                if !hit { return false }
            }
            // Kategorie-Filter
            if let cat = activeCategory, let val = activeValue {
                return value(of: ex, for: cat) == val
            }
            return true
        }
    }

    private func value(of ex: KGGLibraryExercise, for cat: KGGCategoryType) -> String? {
        switch cat {
        case .muskel:   return ex.muskel
        case .gelenk:   return ex.gelenk
        case .geraet:   return ex.geraet
        case .bewegung: return ex.bewegung
        }
    }

    func setFilter(category: KGGCategoryType?, value: String?) {
        activeCategory = category
        activeValue = value
    }

    // MARK: - Kategorie-Werte (für Dropdowns + Filter)

    func categoryValues(_ category: KGGCategoryType, parent: String? = nil) -> [String] {
        (try? repository.fetchCategoryValues(category: category, praxisId: praxisId, parentValue: parent))?
            .map { $0.value } ?? []
    }

    func addCategoryValue(_ category: KGGCategoryType, value: String, parent: String? = nil) {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            try repository.addCategoryValue(category: category, value: trimmed, parentValue: parent, praxisId: praxisId)
        } catch {
            errorMessage = "Kategorie-Wert konnte nicht gespeichert werden"
        }
    }

    // MARK: - Anlegen

    func create(
        title: String,
        muskel: String?, muskelSub: String?,
        gelenk: String?, gelenkSub: String?,
        geraet: String?, geraetSub: String?,
        bewegung: String?, bewegungSub: String?,
        notes: String?
    ) -> KGGLibraryExercise? {
        do {
            let ex = try repository.createExercise(
                title: title,
                praxisId: praxisId,
                muskel: muskel, muskelSub: muskelSub,
                gelenk: gelenk, gelenkSub: gelenkSub,
                geraet: geraet, geraetSub: geraetSub,
                bewegung: bewegung, bewegungSub: bewegungSub,
                notes: notes
            )
            load()
            return ex
        } catch {
            errorMessage = "Übung konnte nicht angelegt werden: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Video importieren (verschlüsselt)

    func importVideo(from item: PhotosPickerItem, into exercise: KGGLibraryExercise) async {
        isImporting = true
        defer { isImporting = false }
        do {
            guard let movie = try await item.loadTransferable(type: VideoFile.self) else {
                errorMessage = "Video konnte nicht geladen werden"
                return
            }
            try repository.attachVideo(sourceURL: movie.url, to: exercise)
            try? FileManager.default.removeItem(at: movie.url)
            load()
        } catch {
            errorMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    // MARK: - Löschen

    func delete(_ exercise: KGGLibraryExercise) {
        do {
            try repository.deleteExercise(exercise)
            load()
        } catch {
            errorMessage = "Löschen fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}

// MARK: - Transferable für Video aus PhotosPicker

struct VideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            try? FileManager.default.removeItem(at: temp)
            try FileManager.default.copyItem(at: received.file, to: temp)
            return VideoFile(url: temp)
        }
    }
}

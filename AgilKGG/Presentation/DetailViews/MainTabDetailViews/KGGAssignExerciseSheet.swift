//
//  KGGAssignExerciseSheet.swift
//  AgilKGG
//
//  Sheet zum Zuweisen von Library-Übungen an einen Patienten.
//  Suche + Kategorie-Filter wie in der Library (gleiche Komponenten).
//  Zwei Wege:
//   • Card antippen  → gemeinsames Parameter-Formular (fullscreen) → einzeln zuweisen
//   • Kreise antippen → mehrere sammeln → alle mit Standardwerten zuweisen
//

import SwiftUI
import SwiftData
import AgilCore

struct KGGAssignExerciseSheet: View {
    @StateObject private var libraryViewModel: KGGLibraryViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    /// Wird pro zugewiesener Übung aufgerufen (Einzel- und Mehrfachauswahl).
    let onAssign: (
        _ exercise: KGGLibraryExercise,
        _ reps: Int,
        _ sets: Int,
        _ weight: Double,
        _ pause: Int,
        _ tempo: String
    ) -> Void

    // Standardwerte für Mehrfachauswahl (identisch zu den KGGExercise-Defaults)
    private let defaultReps = 10
    private let defaultSets = 3
    private let defaultWeight = 0.0
    private let defaultPause = 60
    private let defaultTempo = "2-0-2"

    @State private var multiSelection: Set<UUID> = []
    @State private var exerciseForParams: KGGLibraryExercise?

    private var accent: Color { themeManager.currentTheme.accentColor }

    init(
        modelContext: ModelContext,
        praxisId: UUID,
        onAssign: @escaping (
            _ exercise: KGGLibraryExercise,
            _ reps: Int,
            _ sets: Int,
            _ weight: Double,
            _ pause: Int,
            _ tempo: String
        ) -> Void
    ) {
        _libraryViewModel = StateObject(wrappedValue: KGGLibraryViewModel(modelContext: modelContext, praxisId: praxisId))
        self.onAssign = onAssign
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    KGGLibraryFilterView(viewModel: libraryViewModel, accent: accent)

                    if libraryViewModel.filteredExercises.isEmpty {
                        emptyState
                    } else {
                        exerciseList
                    }
                }
            }
            .navigationTitle("Übung zuweisen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !multiSelection.isEmpty {
                    multiAssignButton
                }
            }
            .fullScreenCover(item: $exerciseForParams) { exercise in
                KGGAssignParamsSheet(exercise: exercise, accent: accent) { reps, sets, weight, pause, tempo in
                    onAssign(exercise, reps, sets, weight, pause, tempo)
                    dismiss()
                }
                .environmentObject(themeManager)
            }
            .onAppear { libraryViewModel.load() }
        }
    }

    // MARK: - Suche

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Übung suchen", text: $libraryViewModel.searchText)
                .autocorrectionDisabled()
            if !libraryViewModel.searchText.isEmpty {
                Button { libraryViewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Liste

    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(libraryViewModel.filteredExercises) { exercise in
                    exerciseRow(exercise)
                }
            }
            .padding(16)
        }
    }

    private func exerciseRow(_ exercise: KGGLibraryExercise) -> some View {
        let isSelected = multiSelection.contains(exercise.id)

        return HStack(spacing: 12) {
            // Thumbnail
            Group {
                if let data = exercise.thumbnailData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Rectangle().fill(Color(.systemGray5))
                        Image(systemName: exercise.hasVideo ? "play.circle.fill" : "video.slash")
                            .foregroundStyle(exercise.hasVideo ? accent : .secondary)
                    }
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Titel + Kategorien
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !exercise.subtitle.isEmpty {
                    Text(exercise.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Auswahlkreis (Mehrfachauswahl)
            Button {
                toggleSelection(exercise)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? accent : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? accent : .clear, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            // Card antippen → Einzelzuweisung mit Parameter-Eingabe
            exerciseForParams = exercise
        }
    }

    private func toggleSelection(_ exercise: KGGLibraryExercise) {
        if multiSelection.contains(exercise.id) {
            multiSelection.remove(exercise.id)
        } else {
            multiSelection.insert(exercise.id)
        }
    }

    // MARK: - Mehrfach zuweisen

    private var multiAssignButton: some View {
        Button {
            assignSelected()
        } label: {
            Text("\(multiSelection.count) Übung\(multiSelection.count == 1 ? "" : "en") hinzufügen")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(accent)
                .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func assignSelected() {
        let selected = libraryViewModel.exercises.filter { multiSelection.contains($0.id) }
        for exercise in selected {
            onAssign(exercise, defaultReps, defaultSets, defaultWeight, defaultPause, defaultTempo)
        }
        dismiss()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 48))
                .foregroundStyle(accent.opacity(0.6))
            Text(libraryViewModel.exercises.isEmpty ? "Keine Übungen in der Bibliothek" : "Keine Treffer")
                .font(.headline)
            if libraryViewModel.exercises.isEmpty {
                Text("Lege zuerst Übungen im Tab \"Übungen\" an.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    libraryViewModel.resetFilters()
                    libraryViewModel.searchText = ""
                } label: {
                    Text("Suche & Filter zurücksetzen")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(accent)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Parameter-Eingabe für die Einzelzuweisung (nutzt das gemeinsame Formular)

private struct KGGAssignParamsSheet: View {
    let exercise: KGGLibraryExercise
    let accent: Color
    let onConfirm: (_ reps: Int, _ sets: Int, _ weight: Double, _ pause: Int, _ tempo: String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var reps = 10
    @State private var sets = 3
    @State private var weight = 0.0
    @State private var pause = 60
    @State private var tempo = "2-0-2"

    var body: some View {
        NavigationStack {
            KGGExerciseParameterForm(
                exerciseTitle: exercise.title,
                thumbnailData: exercise.thumbnailData,
                confirmLabel: "Übung zuweisen",
                accent: accent,
                reps: $reps,
                sets: $sets,
                weight: $weight,
                pause: $pause,
                tempo: $tempo
            ) {
                onConfirm(reps, sets, weight, pause, tempo)
            }
            .navigationTitle("Parameter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

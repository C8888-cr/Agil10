//
//  KGGExerciseEditorView.swift
//  AgilKGG
//
//  Übung bearbeiten — nutzt das gemeinsame KGGExerciseParameterForm
//  (identische Optik wie beim Zuweisen). Wird fullscreen präsentiert.
//  Das Thumbnail kommt vom Aufrufer (Lookup über die videoId in der Library).
//

import SwiftUI
import SwiftData
import AgilCore

struct KGGExerciseEditorView: View {
    @StateObject private var viewModel: KGGExerciseEditorViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    private let thumbnailData: Data?

    init(exercise: KGGExercise, modelContext: ModelContext, patientId: UUID, thumbnailData: Data? = nil) {
        self.thumbnailData = thumbnailData
        _viewModel = StateObject(wrappedValue: KGGExerciseEditorViewModel(
            exercise: exercise,
            modelContext: modelContext,
            patientId: patientId
        ))
    }

    var body: some View {
        NavigationStack {
            KGGExerciseParameterForm(
                exerciseTitle: viewModel.exercise.videoTitle,
                thumbnailData: thumbnailData,
                confirmLabel: "Speichern",
                accent: themeManager.currentTheme.accentColor,
                reps: $viewModel.reps,
                sets: $viewModel.sets,
                weight: $viewModel.weight,
                pause: $viewModel.pause,
                tempo: $viewModel.tempo
            ) {
                save()
            }
            .navigationTitle("Übung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func save() {
        do {
            try viewModel.saveChanges()
            if viewModel.errorMessage == nil {
                dismiss()
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
